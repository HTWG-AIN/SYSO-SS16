#include <linux/cdev.h>
#include <linux/device.h>
#include <linux/fs.h>
#include <linux/init.h>
#include <linux/module.h>

#include <linux/uaccess.h>
#include <linux/slab.h>
#include <linux/string.h>
#include <linux/mutex.h>
#include <linux/sched.h>
#include <linux/wait.h>

//#define CLASSIC_METHOD

#define DEV_NAME "buf"
#ifndef CLASSIC_METHOD
#define REGION_NAME "BUF"
#define CLASS_NAME "buf"
#endif

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Daniel Barea López <da431lop@htwg-konstanz.de>");
MODULE_AUTHOR("Nicolas Wehrle <niwehrle@htwg-konstanz.de>");
MODULE_DESCRIPTION("Linux kernel module developed for the v4 exercise of Systemsoftware in the HTWG Konstanz");
MODULE_DESCRIPTION("Blocking and non-blocking access modes");
MODULE_VERSION("0.1");

#ifdef CLASSIC_METHOD
static int major;
#else
static dev_t dev_number;
static struct cdev *driver_object;
static struct class *class;
#endif

static int driver_open(struct inode *device_file, struct file *instance);
static int driver_release(struct inode *device_file, struct file *instance);
static ssize_t driver_read(struct file *instance, char __user *user, size_t count, loff_t *offset);
static ssize_t driver_write(struct file *instance, const char __user *user, size_t count, loff_t *offset);
static ssize_t read_from_ringbuffer(char __user *user, size_t count);
static ssize_t read_from_buffer(char __user *user, size_t until);
static ssize_t write_to_buffer(const char __user *user, size_t count);
static int lock_mutex(void);

DECLARE_WAIT_QUEUE_HEAD(read_q);
DECLARE_WAIT_QUEUE_HEAD(write_q);

#define buff_size_max 100

static struct file_operations fops = {
    .open = driver_open,
    .release = driver_release,
    .read = driver_read,
    .write = driver_write
};

struct my_bufffer{
    int size;
    char buff[buff_size_max];
    int offset;
};

static struct my_bufffer *buffer;

static DEFINE_MUTEX(mutex);


static int __init mod_init(void) {
    #ifdef CLASSIC_METHOD
    if ((major = register_chrdev(0, DEV_NAME, &fops)) < 0) {
        printk(KERN_ALERT DEV_NAME ": error registering device (%d)\n", major);
        return major;
    }
    printk(KERN_INFO DEV_NAME ": device succesfully registered with major number %d\n", major);
    #else
    if (alloc_chrdev_region(&dev_number, 0, 1, REGION_NAME)) {
        printk(KERN_ERR DEV_NAME ": error in alloc_chrdev_region\n");
        return -EIO;
    }
    if ((driver_object = cdev_alloc()) == NULL) {
        printk(KERN_ERR DEV_NAME ": error in cdev_alloc\n");
        kobject_put(&driver_object->kobj);
        unregister_chrdev_region(dev_number, 1);
        return -EIO;
    }
    driver_object->owner = THIS_MODULE;
    driver_object->ops = &fops;
    if (cdev_add(driver_object, dev_number, 1)) {
        printk(KERN_ERR DEV_NAME ": error in cdev_add\n");
        kobject_put(&driver_object->kobj);
        unregister_chrdev_region(dev_number, 1);
        return -EIO;
    }
    class = class_create(THIS_MODULE, CLASS_NAME);
    device_create(class, NULL, dev_number, NULL, "%s", DEV_NAME);
    printk(KERN_INFO DEV_NAME ": device init succesfully completed\n");
    #endif

  buffer = (struct my_bufffer*) kmalloc(sizeof(struct my_bufffer), GFP_KERNEL);
    if(!buffer){
        printk(KERN_ERR DEV_NAME ": unable to allocate memory.");
    }

    buffer->size = 0;
    buffer->offset = 0;

    return 0;
}

static void __exit mod_exit(void) {
    #ifdef CLASSIC_METHOD
    unregister_chrdev(major, DEV_NAME);
    #else
    device_destroy(class, dev_number);
    class_destroy(class);
    cdev_del(driver_object);
    unregister_chrdev_region(dev_number, 1);
    #endif

    kfree(buffer);

    printk(KERN_INFO DEV_NAME ": device succesfully unregistered\n");
}

static int driver_open(struct inode *device_file, struct file *instance) {
    printk(KERN_DEBUG DEV_NAME ": open called\n");
    return 0;
}

static int driver_release(struct inode *device_file, struct file *instance) {
    printk(KERN_DEBUG DEV_NAME ": release called\n");
    return 0;
}

static int lock_mutex(void){
    mutex_lock(&mutex);
    if (signal_pending(current)) {
        printk(KERN_ERR DEV_NAME ": signal received\n");
        mutex_unlock(&mutex);
        return 1;
    }
    return 0;
}

static ssize_t driver_read(struct file *instance, char __user *user, size_t count, loff_t *offset) {
    ssize_t copied;
    
    printk(KERN_INFO DEV_NAME ": read called\n");

    
    if(count == 0)
        return 0;
    
    if(lock_mutex()) return -EIO;
    while (buffer->size == 0){
        mutex_unlock(&mutex);
        wait_event(read_q,(buffer->size > 0));
        if(lock_mutex()) return -EIO;
    }
    
    copied = read_from_ringbuffer(user,count);
    mutex_unlock(&mutex);
    
    wake_up(&write_q);
    return copied;
    
}

static ssize_t driver_write(struct file *instance, const char __user *user, size_t count, loff_t *offset) {
    size_t written, to_copy;

    printk(KERN_INFO DEV_NAME ": write called\n");

    if(count > buff_size_max){
        to_copy=buff_size_max;
    }else{
        to_copy=count;
    }
    
    if(lock_mutex()) return -EIO;
    while (to_copy > buff_size_max - buffer->size){
        mutex_unlock(&mutex);
        wait_event(write_q,(to_copy <= buff_size_max - buffer->size));
        if(lock_mutex()) return -EIO;

    }
    
    
    written = write_to_buffer(user, to_copy);
    mutex_unlock(&mutex);

    wake_up(&read_q);
    return written;

}

static ssize_t read_from_ringbuffer(char __user *user, size_t count){
    
    size_t copy_until, to_copy1;
    ssize_t copied;
    
    if(count > buffer->size){
        copy_until = buffer->offset + buffer->size;
    } else {
        copy_until = buffer-> offset + count;
    }
    copied = 0;

    if(copy_until >= buff_size_max){
        to_copy1 = buff_size_max - buffer->offset; 
        copied = read_from_buffer(user, buff_size_max-1);

        if(copied != to_copy1)
            return copied;

        buffer -> offset = 0;
    }
    copied += read_from_buffer(user + to_copy1, copy_until % buff_size_max);

    return copied;
    

}


static ssize_t read_from_buffer(char __user *user, size_t until){
    size_t to_copy;
    ssize_t copied;

    to_copy = until - buffer->offset;

    copied = to_copy - copy_to_user(user, buffer->buff + buffer->offset, to_copy);
    buffer->offset += copied;
    buffer->size -= copied;

    return copied;
}

static ssize_t write_to_buffer(const char __user *user, size_t count){
    size_t not_copied, to_copy, rest, copied;
    int end_pointer = (buffer -> offset + buffer->size) % buff_size_max;

    if(count + end_pointer > buff_size_max){
        to_copy = buff_size_max - end_pointer;
        rest = count - to_copy;
    } else {
        to_copy = count;
        rest = 0;
    }


    not_copied = copy_from_user(buffer->buff + end_pointer, user, to_copy);
    copied = to_copy - not_copied;
    buffer->offset += copied;
    buffer->size += copied;

    if(not_copied)
        return copied;

    if(rest){
        not_copied = copy_from_user(buffer->buff, user+copied, rest);
        copied = rest - not_copied;
        buffer->size += copied;
        return count - not_copied;
    }

    return count;
}

module_init(mod_init);
module_exit(mod_exit);

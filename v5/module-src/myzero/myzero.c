#include <linux/cdev.h>
#include <linux/device.h>
#include <linux/fs.h>
#include <linux/init.h>
#include <linux/module.h>
#include <linux/uaccess.h>
#include <linux/slab.h>
#include <linux/string.h>

//#define CLASSIC_METHOD

#define DEV_NAME "myzero"
#ifndef CLASSIC_METHOD
#define REGION_NAME "MYZERO"
#define CLASS_NAME "myzero"
#endif
#define NUM_MINORS 2

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Daniel Barea López <da431lop@htwg-konstanz.de>");
MODULE_AUTHOR("Nicolas Wehrle <niwehrle@htwg-konstanz.de>");
MODULE_AUTHOR("Nicolas Wehrle <niwehrle@htwg-konstanz.de>");
MODULE_DESCRIPTION("Linux kernel module developed for the v4 exercise of Systemsoftware in the HTWG Konstanz");
MODULE_DESCRIPTION("Zero device");
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
static ssize_t driver_read_msg(char *msg, char __user *user, size_t amount);

static struct file_operations fops = {
    .open = driver_open,
    .release = driver_release,
    .read = driver_read
};

struct data {
    char msg[13];
    char zero_msg[2];
    size_t read_counter;
};

static struct data *msg_data;

static int __init mod_init(void) {
    msg_data = (struct data*) kmalloc(sizeof(struct data), GFP_KERNEL);
    if(!msg_data){
        printk(KERN_ERR "Unable to allocate memory.");
    }
    strcpy(msg_data->msg, "Hello World\n");
    strcpy(msg_data->zero_msg, "0");
    msg_data->read_counter = 0;
    
    #ifdef CLASSIC_METHOD
    if ((major = register_chrdev(0, DEV_NAME, &fops)) < 0) {
        printk(KERN_ALERT "Error registering device (%d)\n", major);
        return major;
    }
    printk(KERN_INFO DEV_NAME " device succesfully registered with major number %d\n", major);
    #else
    if (alloc_chrdev_region(&dev_number, 0, NUM_MINORS, REGION_NAME)) {
        printk("Error in alloc_chrdev_region\n");
        return -EIO;
    }
    if ((driver_object = cdev_alloc()) == NULL) {
        printk("Error in cdev_alloc\n");
        kobject_put(&driver_object->kobj);
        unregister_chrdev_region(dev_number, NUM_MINORS);
        return -EIO;
    }
    driver_object->owner = THIS_MODULE;
    driver_object->ops = &fops;
    if (cdev_add(driver_object, dev_number, NUM_MINORS)) {
        printk("Error in cdev_add\n");
        kobject_put(&driver_object->kobj);
        unregister_chrdev_region(dev_number, NUM_MINORS);
        return -EIO;
    }
    class = class_create(THIS_MODULE, CLASS_NAME);
    device_create(class, NULL, dev_number, NULL, "%s", DEV_NAME);
    printk(KERN_INFO DEV_NAME " device init succesfully completed\n");
    #endif
    return 0;
}

static void __exit mod_exit(void) {
    printk(KERN_DEBUG DEV_NAME " number of chars returned:  %d\n", msg_data->read_counter);

    kfree(msg_data);

    #ifdef CLASSIC_METHOD
    unregister_chrdev(major, DEV_NAME);
    #else
    device_destroy(class, dev_number);
    class_destroy(class);
    cdev_del(driver_object);
    unregister_chrdev_region(dev_number, NUM_MINORS);
    #endif
    printk(KERN_INFO DEV_NAME " device succesfully unregistered\n");
}

static int driver_open(struct inode *device_file, struct file *instance) {
    printk(KERN_DEBUG DEV_NAME " open called on minor %d\n", MINOR(device_file->i_rdev));
    return 0;
}

static int driver_release(struct inode *device_file, struct file *instance) {
    printk(KERN_DEBUG DEV_NAME " release called\n");
    return 0;
}

static ssize_t driver_read(struct file *instance, char __user *user, size_t count, loff_t *offset) {
    int minor;

    if(count == 0) {
        return 0;
    }

    if (count == 1) {
        char out[1] = {'\0'};
        msg_data->read_counter++;
        return copy_to_user(user, out, 1) - 1;
    }

    minor = iminor(instance->f_path.dentry->d_inode);
    printk(KERN_DEBUG DEV_NAME " read called on minor %d\n", minor);
    
    switch (minor) {
        case 0:
            return driver_read_msg(msg_data->zero_msg, user, count);
        case 1:
            return driver_read_msg(msg_data->msg, user, count);
        default:
            return -ENOSYS;
    }
}

static ssize_t driver_read_msg(char *msg, char __user *user, size_t amount){
    size_t to_copy, lenght;
    ssize_t copied;

    lenght = strlen(msg) + 1;
    to_copy = min(lenght, amount);
    copied = to_copy - copy_to_user(user, msg, to_copy);

    if (copied + 1 < lenght)  {
        memcpy(msg, (msg+copied), lenght - copied);
    } else {
        strcpy(msg, "0");
    }

    msg_data->read_counter += copied;

    return copied;
}

module_init(mod_init);
module_exit(mod_exit);

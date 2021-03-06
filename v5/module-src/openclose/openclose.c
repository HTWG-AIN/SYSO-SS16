#include <linux/atomic.h>
#include <linux/cdev.h>
#include <linux/device.h>
#include <linux/fs.h>
#include <linux/init.h>
#include <linux/module.h>

//#define CLASSIC_METHOD

#define DEV_NAME "openclose"
#ifndef CLASSIC_METHOD
#define REGION_NAME "OPENCLOSE"
#define CLASS_NAME "openclose"
#endif

#define NUM_MINORS 2
#define MAX_PROCS 1

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Daniel Barea López <da431lop@htwg-konstanz.de>");
MODULE_AUTHOR("Nicolas Wehrle <niwehrle@htwg-konstanz.de>");
MODULE_DESCRIPTION("Linux kernel module developed for the v4 exercise of Systemsoftware in the HTWG Konstanz");
MODULE_DESCRIPTION("");
MODULE_VERSION("0.1");

#ifdef CLASSIC_METHOD
static int major;
#else
static dev_t dev_number;
static struct cdev *driver_object;
static struct class *class;
#endif

static atomic_t lock = ATOMIC_INIT(MAX_PROCS);

static int driver_open(struct inode *device_file, struct file *instance);
static int driver_release(struct inode *device_file, struct file *instance);
static ssize_t driver_read(struct file *instance, char __user *user, size_t count, loff_t *offset);
static ssize_t driver_write(struct file *instance, const char __user *user, size_t count, loff_t *offset);
static ssize_t driver_read_single(struct file *instance, char __user *user, size_t count, loff_t *offset);
static ssize_t driver_write_single(struct file *instance, const char __user *user, size_t count, loff_t *offset);

static struct file_operations fops = {
    .open = driver_open,
    .release = driver_release
};

static int __init mod_init(void) {
    #ifdef CLASSIC_METHOD
    if ((major = register_chrdev(0, DEV_NAME, &fops)) < 0) {
        printk(KERN_ALERT DEV_NAME ": error registering device (%d)\n", major);
        return major;
    }
    printk(KERN_INFO DEV_NAME ": device succesfully registered with major number %d\n", major);
    #else
    if (alloc_chrdev_region(&dev_number, 0, NUM_MINORS, REGION_NAME)) {
        printk(KERN_ERR DEV_NAME ": error in alloc_chrdev_region\n");
        return -EIO;
    }
    if ((driver_object = cdev_alloc()) == NULL) {
        printk(KERN_ERR DEV_NAME ": error in cdev_alloc\n");
        kobject_put(&driver_object->kobj);
        unregister_chrdev_region(dev_number, NUM_MINORS);
        return -EIO;
    }
    driver_object->owner = THIS_MODULE;
    driver_object->ops = &fops;
    if (cdev_add(driver_object, dev_number, NUM_MINORS)) {
        printk(KERN_ERR DEV_NAME ": error in cdev_add\n");
        kobject_put(&driver_object->kobj);
        unregister_chrdev_region(dev_number, NUM_MINORS);
        return -EIO;
    }
    class = class_create(THIS_MODULE, CLASS_NAME);
    device_create(class, NULL, dev_number, NULL, "%s", DEV_NAME);
    printk(KERN_INFO DEV_NAME ": device init succesfully completed\n");
    #endif
    return 0;
}

static void __exit mod_exit(void) {
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
    printk(KERN_DEBUG DEV_NAME ": open called on minor %d\n", MINOR(device_file->i_rdev));
    switch (MINOR(device_file->i_rdev)) {
        case 1:
            // Behavior for minor 1
            if (!atomic_dec_and_test(&lock)) {
                atomic_inc(&lock);
                printk(KERN_ERR DEV_NAME ": already in use\n");
                return -EBUSY;
            }
            fops.read = driver_read_single;
            fops.write = driver_write_single;
            break;
        default:
            // Behavior for other minors
            fops.read = driver_read;
            fops.write = driver_write;
    }
    return 0;
}

static int driver_release(struct inode *device_file, struct file *instance) {
    printk(KERN_DEBUG DEV_NAME ": release called on minor %d\n", MINOR(device_file->i_rdev));
    switch (MINOR(device_file->i_rdev)) {
        case 1:
            atomic_inc(&lock);
    }
    return 0;
}

static ssize_t driver_read(struct file *instance, char __user *user, size_t count, loff_t *offset) {
    printk(KERN_DEBUG DEV_NAME ": NORMAL read called\n");
    return 0;
}

static ssize_t driver_write(struct file *instance, const char __user *user, size_t count, loff_t *offset) {
    printk(KERN_DEBUG DEV_NAME ": NORMAL write called\n");
    return 0;
}

static ssize_t driver_read_single(struct file *instance, char __user *user, size_t count, loff_t *offset) {
    printk(KERN_DEBUG DEV_NAME ": SINGLE read called\n");
    return 0;
}

static ssize_t driver_write_single(struct file *instance, const char __user *user, size_t count, loff_t *offset) {
    printk(KERN_DEBUG DEV_NAME ": SINGLE write called\n");
    return 0;
}

module_init(mod_init);
module_exit(mod_exit);

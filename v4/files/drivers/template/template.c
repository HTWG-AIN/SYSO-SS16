#include <linux/cdev.h>
#include <linux/device.h>
#include <linux/fs.h>
#include <linux/init.h>
#include <linux/module.h>

//#define CLASSIC_METHOD

#define DEV_FILENAME "template_device"
#ifndef CLASSIC_METHOD
#define REGION_NAME "TEMPLATE"
#define CLASS_NAME "template"
#endif

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Daniel Barea López <da431lop@htwg-konstanz.de>");
MODULE_AUTHOR("Nicolas Wehrle <niwehrle@htwg-konstanz.de>");
MODULE_DESCRIPTION("Linux kernel module developed for the v4 exercise of Systemsoftware in the HTWG Konstanz");
MODULE_DESCRIPTION("The module creates the device /dev/test_device, that stores and reads a message written by the user");
MODULE_VERSION("0.1");

#ifdef CLASSIC_METHOD
static int major;
#else
static dev_t template_dev_number;
static struct cdev *driver_object;
static struct class *template_class;
#endif

static int device_open(struct inode *inode, struct file *file) {
    return 0;
}

static int device_release(struct inode *inode, struct file *file) {
    return 0;
}

static struct file_operations fops = {
    .open = device_open,
    .release = device_release
};

static int __init mod_init(void) {
    #ifdef CLASSIC_METHOD
    if ((major = register_chrdev(0, DEV_FILENAME, &fops)) < 0) {
        printk(KERN_ALERT "Error registering device (%d)\n", major);
        return major;
    }
    printk(KERN_INFO "Template device succesfully registered with major number %d\n", major);
    #else
    if (alloc_chrdev_region(&template_dev_number, 0, 1, REGION_NAME)) {
        printk("Error in alloc_chrdev_region\n");
        return -EIO;
    }
    if ((driver_object = cdev_alloc()) == NULL) {
        printk("Error in cdev_alloc\n");
        kobject_put(&driver_object->kobj);
        unregister_chrdev_region(template_dev_number, 1);
        return -EIO;
    }
    driver_object->owner = THIS_MODULE;
    driver_object->ops = &fops;
    if (cdev_add(driver_object, template_dev_number, 1)) {
        printk("Error in cdev_add\n");
        kobject_put(&driver_object->kobj);
        unregister_chrdev_region(template_dev_number, 1);
        return -EIO;
    }
    template_class = class_create(THIS_MODULE, CLASS_NAME);
    device_create(template_class, NULL, template_dev_number, NULL, "%s", DEV_FILENAME);
    printk(KERN_INFO "Template device init succesfully completed\n");
    #endif
    return 0;
}

static void __exit mod_exit(void) {
    #ifdef CLASSIC_METHOD
    unregister_chrdev(major, DEV_FILENAME);
    #else
    device_destroy(template_class, template_dev_number);
    class_destroy(template_class);
    cdev_del(driver_object);
    unregister_chrdev_region(template_dev_number, 1);
    #endif
    printk(KERN_INFO "Template device succesfully unregistered\n");
}

module_init(mod_init);
module_exit(mod_exit);

#include <linux/cdev.h>
#include <linux/device.h>
#include <linux/fs.h>
#include <linux/init.h>
#include <linux/module.h>
#include <linux/uaccess.h>

//#define CLASSIC_METHOD

#define DEV_NAME "myzero"
#ifndef CLASSIC_METHOD
#define REGION_NAME "MYZERO"
#define CLASS_NAME "myzero"
#endif

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Daniel Barea López <da431lop@htwg-konstanz.de>");
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

static struct file_operations fops = {
    .open = driver_open,
    .release = driver_release,
    .read = driver_read
};

static int __init mod_init(void) {
    #ifdef CLASSIC_METHOD
    if ((major = register_chrdev(0, DEV_NAME, &fops)) < 0) {
        printk(KERN_ALERT "Error registering device (%d)\n", major);
        return major;
    }
    printk(KERN_INFO DEV_NAME " device succesfully registered with major number %d\n", major);
    #else
    if (alloc_chrdev_region(&dev_number, 0, 1, REGION_NAME)) {
        printk("Error in alloc_chrdev_region\n");
        return -EIO;
    }
    if ((driver_object = cdev_alloc()) == NULL) {
        printk("Error in cdev_alloc\n");
        kobject_put(&driver_object->kobj);
        unregister_chrdev_region(dev_number, 1);
        return -EIO;
    }
    driver_object->owner = THIS_MODULE;
    driver_object->ops = &fops;
    if (cdev_add(driver_object, dev_number, 1)) {
        printk("Error in cdev_add\n");
        kobject_put(&driver_object->kobj);
        unregister_chrdev_region(dev_number, 1);
        return -EIO;
    }
    class = class_create(THIS_MODULE, CLASS_NAME);
    device_create(class, NULL, dev_number, NULL, "%s", DEV_NAME);
    printk(KERN_INFO DEV_NAME " device init succesfully completed\n");
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
    unregister_chrdev_region(dev_number, 1);
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
    size_t to_copy, not_copied;
    char *msg;

    minor = iminor(instance->f_path.dentry->d_inode);
    printk(KERN_DEBUG DEV_NAME " read called on minor %d\n", minor);
    switch (minor) {
        case 0:
            msg = "0";
            break;
        case 1:
            msg = "Hello World\n";
        default:
            return -ENOSYS;
    }
    to_copy = min(strlen(msg) + 1, count);
    not_copied = copy_to_user(user, msg, to_copy);
    return to_copy - not_copied;
}

module_init(mod_init);
module_exit(mod_exit);

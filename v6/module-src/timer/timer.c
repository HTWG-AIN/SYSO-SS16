#include <linux/cdev.h>
#include <linux/cpufreq.h>
#include <linux/device.h>
#include <linux/fs.h>
#include <linux/init.h>
#include <linux/module.h>
#include <linux/timex.h>

//#define CLASSIC_METHOD
//#define WAIT_COMPLETION

#define DEV_NAME "timer"
#ifndef CLASSIC_METHOD
#define REGION_NAME "TIMER"
#define CLASS_NAME "timer"
#endif

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Daniel Barea López <da431lop@htwg-konstanz.de>");
MODULE_AUTHOR("Nicolas Wehrle <niwehrle@htwg-konstanz.de>");
MODULE_DESCRIPTION("Linux kernel module developed for the v4 exercise of Systemsoftware in the HTWG Konstanz");
MODULE_DESCRIPTION("Module to test the Linux kernel's timer usage and functionalities");
MODULE_DESCRIPTION("The module will implement a timer called every 2 seconds and print the spent time (in jiffies) and the maximum and minimum time");
MODULE_VERSION("0.1");

#ifdef CLASSIC_METHOD
static int major;
#else
static dev_t dev_number;
static struct cdev *driver_object;
static struct class *class;
#endif

static struct file_operations fops = {};

static struct timer_list timer;
#ifdef WAIT_COMPLETION
static atomic_t stop_timer = ATOMIC_INIT(0);
static DECLARE_COMPLETION(timer_completion);
#endif
static unsigned long min, max, curr, prev = 0;

static void timer_function(unsigned long arg) {
    if (prev) {
        curr = jiffies - prev;
        max = max > curr ? max : curr;
        min = min < curr && min ? min : curr;
        printk(KERN_INFO DEV_NAME ": timer expired after %lu jiffies (min = %lu, max = %lu)\n", curr, min, max);
    }
    prev = jiffies;
    // Program the timer to interrupt again
    timer.expires = jiffies + 2 * HZ;
    #ifdef WAIT_COMPLETION
    if (atomic_read(&stop_timer)) {
        complete(&timer_completion);
    } else {
        add_timer(&timer);
        printk(KERN_DEBUG DEV_NAME ": scheduling timer after another 2 seconds\n");
    }
    #else
    printk(KERN_DEBUG DEV_NAME ": scheduling timer after another 2 seconds\n");
    add_timer(&timer);
    #endif
}

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

    init_timer(&timer);
    timer.function = timer_function;
    timer.data = 0;
    timer.expires = jiffies + 2 * HZ;
    add_timer(&timer);
    printk(KERN_DEBUG DEV_NAME ": timer initialized succesfully\n");

    return 0;
}

static void __exit mod_exit(void) {
    #ifdef WAIT_COMPLETION
    printk(KERN_DEBUG DEV_NAME ": cancelling timer re-scheduling after next timeout\n");
    atomic_set(&stop_timer, 1);
    wait_for_completion(&timer_completion);
    #else
    if (del_timer(&timer)) {
        printk(KERN_DEBUG DEV_NAME ": timer succesfully deactivated (was still active)\n");
    } else {
        printk(KERN_DEBUG DEV_NAME ": timer succesfully deactivated (was inactive)\n");
    }
    #endif

    #ifdef CLASSIC_METHOD
    unregister_chrdev(major, DEV_NAME);
    #else
    device_destroy(class, dev_number);
    class_destroy(class);
    cdev_del(driver_object);
    unregister_chrdev_region(dev_number, 1);
    #endif
    printk(KERN_INFO DEV_NAME ": device succesfully unregistered\n");
}

module_init(mod_init);
module_exit(mod_exit);

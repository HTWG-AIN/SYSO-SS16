#include <linux/init.h>
#include <linux/module.h>

MODULE_LICENSE("GPL");

static int __init mod_init(void) {
    printk(KERN_ALERT "Hello, world!\n");
    return 0;
}

static void __exit mod_exit(void) {
    printk(KERN_ALERT "Goodbye, cruel world!\n");
}

module_init(mod_init);
module_exit(mod_exit);

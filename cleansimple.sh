    # #!/bin/sh
    #
    # cronjob
    # 0 8 1 * * /usr/local/dokuwiki/cleansimple.sh 2>&1 > /dev/null
    #
    # set the path to your DokuWiki installation here
    DOKUWIKI=/usr/local/dokuwiki

    # purge files older than 30 days from the attic and media_attic
    find $DOKUWIKI/data/attic/ -type f -mtime +30 -exec rm -f {} \;
    find $DOKUWIKI/data/media_attic/ -type f -mtime +30 -exec rm -f {} \;

    # remove stale lock files
    find $DOKUWIKI/data/pages/ -name '*.lock' -type f -mtime +1 -exec rm -f {} \;

    # remove files older than 2 days from the cache
    find $DOKUWIKI/data/cache -type f -mtime +2 -exec rm -f {} \;

    # remove empty directories
    # disabled - causes unwanted remove of directories
    #find $DOKUWIKI/data/pages/ -depth -type d -empty -exec rmdir {} \; 

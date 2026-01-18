#!/bin/sh

echo "Waiting for WordPress to be ready..."
sleep 10

until wp core is-installed; do
    echo "WordPress is not installed yet. Waiting..."
    sleep 5
done

echo "WordPress core is ready."

if ! wp plugin is-installed redis-cache; then
    echo "Installing Redis Cache plugin..."
    wp plugin install redis-cache --activate
else
    echo "Redis Cache plugin is already installed."
    wp plugin activate redis-cache
fi

echo "Enabling Redis Object Cache..."
wp redis enable --force

wp redis status
# Magnolia Runtime Environment

This image provides a servlet container and a few script to run a Magnolia instance. The Tag denotes the version of Tomcat and of the JRE used.

## Building & Pushing

To build the images again run `build-images.sh`:

```
./build-images.sh
```

 To extend the Tomcat tags and variants to build, adjust the arrays inside the script.

If you want to push the images directly to the Docker Hub run:

```
./build-images.sh -p
```
# Example 🚀

This is an example repo, showing a few different ways that a component can be onboarded to [konflux-ci](https://konflux-ci.dev) to demonstrate different degrees of supply chain security. 🔒

* [component-01](component-01/) is a basic build. It installs some **python wheels** 🐍 and does so directly from https://pypi.org, with network access during build. _We cannot be as certain about the supply chain properties of this component as we can be of others._ ⚠️
* [component-02](component-02/) is similar to component-01, except that it **curls an installer script** from some third party site and executes it. _What's a platform to do?_ 🤔
* [component-03](component-03/) only installs **python dependencies** 🐍, but here we have **enabled konflux [hermetic builds](https://konflux-ci.dev/docs/building/hermetic-builds/)** 🛡️ which requires konflux to [prefetch the python content](https://konflux-ci.dev/docs/building/prefetching-dependencies/#pip) and rebuild those wheels from source. _This gives us a higher degree of certainty about what went into the build._ ✅
* [component-04](component-04/) **curls an installer script** from a third party site, but does so through **konflux's hermetic build mechanism**. _This gives us a strong evidence trail for the build, clear provenance, and a clear SBOM._ 📜

## Sneaky 🕵️‍♂️

That installer script is served by an instance of [ralphbean/sneaky](https://github.com/ralphbean/sneaky/blob/main/server.py). 🐍

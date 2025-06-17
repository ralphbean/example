# Example 🚀

This is an example repo, showing a few different ways that a component can be onboarded to [konflux-ci](https://konflux-ci.dev) to demonstrate different degrees of supply chain security. 🔒

* [component-01](component-01/) is a basic build. It installs some **python wheels** 🐍 and does so directly from https://pypi.org, with network access during build. _We cannot be as certain about the supply chain properties of this component as we can be of others._ ⚠️
* [component-02](component-02/) is similar to component-01, except that it **curls an installer script** from some third party site and executes it. _What's a platform to do?_ 🤔
* [component-03](component-03/) only installs **python dependencies** 🐍, but here we have **enabled konflux [hermetic builds](https://konflux-ci.dev/docs/building/hermetic-builds/)** 🛡️ which requires konflux to [prefetch the python content](https://konflux-ci.dev/docs/building/prefetching-dependencies/#pip) and rebuild those wheels from source. _This gives us a higher degree of certainty about what went into the build._ ✅
* [component-04](component-04/) **curls an installer script** from a third party site, but does so through **konflux's hermetic build mechanism**. _This gives us a strong evidence trail for the build, clear provenance, and a clear SBOM._ 📜

### How to use this repo

* Set up konflux locally in [kind](https://kind.sigs.k8s.io/) by following the instructions in [konflux-ci/konflux-ci](https://github.com/konflux-ci/konflux-ci)
* Fork this repo and clone your fork locally. Then, replace all ralphbean references with references to your work with:

```bash
find * -type f -exec sed -i 's/ralphbean/your-github-username-goes-here/' {} \;
```

* Set up these example resources in your local konflux instance with:

```bash
for dirname in component-0*/resources/; do kubectl apply -k $dirname; done
```

* Commit and push your local changes to your fork.

```bash
git add .
git commit -m 'Switch from user ralphbean to your-github-username-goes-here'
git push origin main
```

* Login to your local konflux instance at https://localhost:9443/ns/your-github-username-goes-here/ to see your builds.

## component-01

This demonstrates a basic build. Let's use it to look at Konflux's basic capabilities.

Borrowing from the [s3c2f framework](https://github.com/ossf/s2c2f/blob/main/specification/framework.md):

| **Practice** | **Requirement** | **Maturity Level** | **Requirement Title** | **Benefit** | **Konflux** |
| --- | --- | --- | --- | --- | --- |
| *Scan*     | SCA-1 | L1 | Scan OSS for known vulnerabilities (i.e. CVEs, GitHub Advisories, etc.) | Able to update OSS to reduce risks | Run clair to find vulnerabilities |
| *Update*   | UPD-3 | L2 | Display OSS vulnerabilities in developer contribution flow (i.e. Pull Requests). | PR reviewer doesn't want to approve knowing that there are unaddressed vulnerabilities. | Surface CVEs in build UI and policy gate |
| *Update*   | UPD-2 | L2 | Enable automated OSS updates | Improve MTTR to patch faster than adversaries can operate | Konflux instance of [renovate](https://github.com/renovatebot/renovate) updates deps |

## component-02

This demonstrates a build where something bad has happened. We weren't following best practices and were the target of an attack.

Look at the logs of the build and/or launch the image as a container and investigate the contents of `install.sh`!

Run `syft` against the image and the repo. Is there evidence of the attack?

## component-03

| **Practice** | **Requirement** | **Maturity Level** | **Requirement Title** | **Benefit** | **Konflux** |
| --- | --- | --- | --- | --- | --- |
| *Ingest*   | ING-3 | L3 | Have a Deny List capability to block known malicious OSS from being consumed | Prevents ingestion of known malware by blocking ingestion as soon as a critically vulnerable OSS component is identified, such as [colors v 1.4.1](https://security.snyk.io/vuln/SNYK-JS-COLORS-2331906), or if an OSS component is deemed malicious | [conforma](https://conforma.dev/) policy gives control at release time |
| *Ingest*   | ING-4 | L3 | Mirror a copy of all OSS source code to an internal location | Business Continuity and Disaster Recovery (BCDR) scenarios. Also enables proactive security scanning, fix it scenarios, and ability to rebuild OSS in a trusted build environment. | Source artifacts stored in OCI registry, as well as all intermediary artifacts for a strong evidence trail |

## component-04

| **Practice** | **Requirement** | **Maturity Level** | **Requirement Title** | **Benefit** | **Konflux** |
| --- | --- | --- | --- | --- | --- |
| *Audit*    | AUD-2 | L2 | Audit that developers are consuming OSS through the approved ingestion method | Detect when developers consume OSS that isn&#39;t detected by your inventory or scan tools | Hermetic builds ensure that sources are exposed in the manifest for audit and control |
| *Enforce*  | ENF-2 | L3 | Enforce usage of a curated OSS feed that enhances the trust of your OSS | Curated OSS feeds can be systems that scan OSS for malware, validate claims-metadata about the component, or systems that enforce an allow/deny list. Developers should not be allowed to consume OSS outside of the curated OSS feed | [conforma](https://conforma.dev/) prohibits the use of unauthorized sources |

## Sneaky 🕵️

That installer script is served by an instance of [ralphbean/sneaky](https://github.com/ralphbean/sneaky/blob/main/server.py). 🐍


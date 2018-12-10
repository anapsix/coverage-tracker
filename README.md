# coverage-tracker
Simple service tracking coverage, using Redis as storage. It returns previously reported coverage, or `302` redirects to badge URL by [shields.io](https://shields.io/)

## Usage Examples

### GET /:repo/:branch - retrieve coverage for :branch of a :repo

    ## Example
    ## curl -X GET -D- "http://localhost:4567/my-project/?shields=true&low=30&high=75"

    :repo - name of the repo (required)
    :branch - name of the branch (optional, defaults to "master")

    args['shields']    - flag, return shields URL (optional)
                         activated with `1`, `on`, `yes`, `true`
    args['low']        - when `coverage <= low`, displays red badge (optional, defaults to 30.0)
    args['high']       - when `coverage >= high`, displays green badge (optional, defaults to 75.0)
    args['fileformat'] - fileformat to request from shields.io (optional, defaults to "svg")
    args['style']      - style of the badge from shields.io (optional, defaults to "for-the-badge")
    args['prefix']     - prefix to coverage digits on the badge (optional, defaults to "coverage")
                         disabled completely with `0`, `off`, `no`, `false`

For defaults, see "configure" block in [`main.rb`](./main.rb).

For fileformat and styles see [shields.io](https://shields.io/).

### POST /:repo/:branch - record coverage for :branch of a :repo

    ## Example
    ## curl -X POST http://localhost:4567/my-project/ -d '{"coverage":"23.3"}'

Start with

    bundle install
    bundle exec ruby ./main.rb

### Docker

    docker build -t coverage-tracker .
    docker run -d --name redis --rm -p 6379:6379 redis:alpine
    docker run -d --name ct --rm --link redis:red -e REDIS_HOST=red -p 8080:8080 coverage-tracker
    curl -X POST "http://localhost:8080/project-name/master" -d '{"coverage":"48.00"}'
    curl -sS --fail "http://localhost:8080/project-name/master"
    curl -sS "http://localhost:8080/project-name/master?shields=1&debug=1"
    curl -sS -D- -o/dev/null "http://localhost:8080/project-name/master?shields=1"


### Kubernetes
Take a look at sample [`./k8s/coverage-tracker.yaml`](./k8s/coverage-tracker.yaml) manifest as example of simple deployment in K8s

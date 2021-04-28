
[![New Relic Experimental header](https://github.com/newrelic/opensource-website/raw/master/src/images/categories/Experimental.png)](https://opensource.newrelic.com/oss-category/#new-relic-experimental)

# Security Tooling 

>The New Relic Security Tooling repository provides code which the security team at New Relic uses to monitor and detect potential threats. Currently, scripts are included to pull logs from Okta and Duo, send to New Relic and set up accompanying Dashboard code to view relevant events.

## Installing and using the Security Tooling scripts

### Okta Log Puller 

The ``okta_log_puller.rb`` script pulls the previous 5 minutes worth of Okta log data and pushes this to New Relic. For long term use this should be set up to run as a cron job every 5 minutes to continuously pull data. 

*Required Environment Variable Values*

* ``NR_ACCOUNT_ID`` - the numerical ID of the New Relic account
* ``OKTA_ENDPOINT`` & ``PROD_OKTA_ENDPOINT`` - Okta connection endpoints (usually <>.okta.com) 
* ``OKTA_API_TOKEN`` & ``PROD_OKTA_API_TOKEN`` - [Okta API tokens](https://developer.okta.com/docs/guides/create-an-api-token/overview/) with ReadOnly permissions  

The ``okta_sample_dashboard.json`` includes sample New Relic dashboard code, which can be imported into New Relic following [these instructions](https://docs.newrelic.com/docs/query-your-data/explore-query-data/dashboards/introduction-dashboards/#dashboards-import). Replace the below values.

*Required Values*

* Replace the ``$ACCOUNT_ID`` with the numerical ID of the New Relic account
* Replace the ``$COMPANY_DOMAIN_NAME`` with your company domain name for email to use this query

### Duo Log Puller 

The ``duo_log_puller.rb`` script pulls the previous 5 minutes worth of Duo log data and pushes this to New Relic. For long term use this should be set up to run as a cron job every 5 minutes to continuously pull data. 

*Required Environment Variable Values*
* ``NR_ACCOUNT_ID`` - the numerical ID of the New Relic account
* ``DUO_HOST`` - Duo connection endpoint
* ``DUO_IKEY`` - [Duo integration key](https://duo.com/docs/authapi#first-steps)
& ``DUO_SKEY`` - Duo secret key 

The ``duo_sample_dashboard.json`` includes sample New Relic dashboard code, which can be imported into New Relic following [these instructions](https://docs.newrelic.com/docs/query-your-data/explore-query-data/dashboards/introduction-dashboards/#dashboards-import). Replace the below values.

*Required Values*

* Replace the ``$ACCOUNT_ID`` with the numerical ID of the New Relic account


## Support

New Relic hosts and moderates an online forum where customers can interact with New Relic employees as well as other customers to get help and share best practices. 

## Contributing

We encourage your contributions to improve Security Tooling! Keep in mind that when you submit your pull request, you'll need to sign the CLA via the click-through using CLA-Assistant. You only have to sign the CLA one time per project.
If you have any questions, or to execute our corporate CLA (which is required if your contribution is on behalf of a company), drop us an email at opensource@newrelic.com.

**A note about vulnerabilities**

As noted in our [security policy](../../security/policy), New Relic is committed to the privacy and security of our customers and their data. We believe that providing coordinated disclosure by security researchers and engaging with the security community are important means to achieve our security goals.

If you believe you have found a security vulnerability in this project or any of New Relic's products or websites, we welcome and greatly appreciate you reporting it to New Relic through [HackerOne](https://hackerone.com/newrelic).


## License
Security Tooling is licensed under the [Apache 2.0](http://apache.org/licenses/LICENSE-2.0.txt) License.

# ChangeLog

## NEXT

  *

## v2.0.0 (2013-11-21)

  * Ruby `>= 1.9.3` only.

## v1.0.15 (2013-11-15)

  * Add a `resolve_one` method to `AppEnvironment` to assist scripting
  * Tighter requirement on `rest-client` gem. `1.6.0` does not actually work.
  * Force instance addition with util to require a name, specify name when removing instances

## v1.0.14 (2013-09-04)

  * Add sorting comparator spaceship (&lt;=&gt;) to each of the models.

## v1.0.13 (2013-08-13)

  * `Environment.by_name` using resolver
  * `Environment#remove_instance` with a given instance object removes an instance via API
  * Find instance by its AWSM id
  * Find an environment by its name off the `api` object
  * Add an instance to an environment
  * Identify the license as MIT in the gemspec
  * Make tests pass on travis

## v1.0.12 (2013-05-31)

  * Fix for ruby 2.0.0

## v1.0.11 (2013-03-07)

  * Supports Instance#availability\_zone in API response.
  * Renames Deployment#cancel to Deployment#timeout, though still support using #cancel.

## v1.0.10 (2013-02-20)

  * Provide a test scenario for stuck deployments

## v1.0.9 (2013-02-20)

  * Add the ability to cancel stuck deployments

## v1.0.8 (2013-02-14)

  * Loosen the multi\_json gem version requirement to allow 1.0 compatible security fixes.

## v1.0.7 (2012-10-25)

  * Send serverside\_version to the deployment API when starting a deploy.

## v1.0.6 (2012-08-20)

  *

## v1.0.5 (2012-08-14)

  *

## v1.0.4 (2012-08-14)

  * Send input\_ref to deployments in the extra config.
  * Use Connection object to take over for all api communication, simplifying the CloudClient class.
  * Interface for creating a CloudClient has changed to support new Connection class.

## v1.0.3 (2012-06-13)

  *

## v1.0.2 (2012-05-29)

  *

## v1.0.1 (2012-05-22)

  * Includes fixes for deployment test harness used by this gem and engineyard gem

## v1.0.0 (2012-05-22)

  * First attempt at a real release.
  * Provides all the functionality that is needed for engineyard gem to operate.
  * Like Torchwood, The Colbert Report, and The Cleveland Show, start CloudClient's new life as a spin-off.


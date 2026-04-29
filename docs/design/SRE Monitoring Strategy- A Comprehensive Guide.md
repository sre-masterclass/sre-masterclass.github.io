# Site Reliability Engineering: Monitoring Complex Systems

## Introduction

A solid monitoring strategy can mean the difference between understanding the software you build and being completely oblivious to how it actually runs in production. If you help build complex systems that make it into real production environments, this guide is for you. This is a no-nonsense primer into the world of monitoring complex systems.

## What is Monitoring?

Monitoring can be defined as collecting, processing, aggregating, and displaying real-time quantitative data about a system. You can monitor a system in any type of environment, from development to production.

### Development vs. Production Monitoring

Your monitoring strategy during development might be fairly casual and mostly involve pumping log statements to your console output. This is the most basic approach to monitoring that many of us use when coding something new. For instance, if we're building a new RESTful API, it might be common to test this API with curl or Postman and add log statements to the code that output various log lines.

But how does your CPU behave during this test? What about other resources like memory and disk usage? If we want to take things to the next level, maybe we fire off a bunch of curl statements at our new API while keeping an eye on htop. If we see something suspicious, maybe we make some code tweaks here and there. Eventually, if we gain a reasonable amount of confidence during this testing, we declare mission accomplished—our code is ready for production.

### The Production Challenge

But what's our monitoring strategy after we go to production? We can't exactly SSH into random nodes, kick off htop, and hope to make any sense of the results. Even if we could, this would be horribly inefficient. Instead, we need a well-thought-out monitoring strategy in place for our production systems. After all, a cornerstone of operational visibility is monitoring.

This guide introduces a patterns-based approach to monitoring. Many teams monitor their systems in production, but how many teams do so efficiently? How many teams do so in a way that helps scale their operational and SRE teams? To help us achieve a high level of operational visibility while also scaling our teams, let's talk about monitoring taxonomies.

## Monitoring Taxonomies

### What is a Monitoring Taxonomy?

A monitoring taxonomy is based around two central concepts: the **measurement** and the **resource**.

All taxonomies mix and match from a standard vocabulary of measurements—the metrics that a taxonomy proposes we measure. Measurements include:
- Latency
- Traffic
- Errors
- Saturation
- Rate
- Duration
- Utilization
- Amendments
- Anomalies
- Failures

A **resource** is essentially any discrete component of a system, including hardware and software components. Examples of resources include CPUs, disks, APIs, load balancers, and so forth.

### Overview of Popular Taxonomies

Let's start with an overview of each taxonomy and the measurements it captures:

- **Google's Four Golden Signals**: measures latency, traffic, errors, and saturation
- **RED**: measures rate, errors, and duration
- **USE**: measures utilization, saturation, and errors
- **SAFE**: measures saturation, amendments, anomalies, failures, and errors

### The Patterns-Based Approach

An important concept to cover is that each taxonomy proposes what measurements to capture, but the taxonomies don't specify what resources to put under measurement. That should be a notable part of your technical design.

For instance, RED suggests that we should measure rate, errors, and duration, but it doesn't specify that we should measure these metrics for disks, CPUs, or APIs. That part's up to you.

The monitoring taxonomies we cover provide a pattern to help standardize how we capture and display metrics but don't dictate what resources we put under measurement. This brings us to the central point: promoting a patterns-based approach to monitoring.

Imagine you have hundreds of microservices. If you decide across your organization that every microservice in production will be monitored using RED metrics, this means that an Ops team can standardize everything from alerting to automation and runbooks for APIs based on a single taxonomy—RED. Without a standard approach, every single microservice might monitor seemingly random metrics, which makes scaling out a production operations team really challenging as a system grows.

As we dive deeper, think about one thing: Can I find patterns to help efficiently scale out the operational visibility of a complex system in the most simple way possible?

## Resource Types

There are three main categories of resources that we can monitor:

### 1. Functional Server Components
These include CPUs, disks, memory, and I/O, among other low-level resources in the infrastructure itself. This category of monitoring is basically constrained by the runtime environment, whether that's Kubernetes or the cloud provider you're using in production like AWS or GCP. For the most part, any runtime is going to let you monitor basic functional server components.

### 2. Low-Level Software Components
These include locks, threads, stacks, heaps, and garbage collectors. Modern languages provide very good monitoring of low-level software components, like the Java Flight Recorder for the Java Virtual Machine, which is a lightweight resource profiler built into the JVM itself. Low-level software monitoring is basically constrained by the language you're using and the tooling options available in that language's ecosystem.

### 3. Endpoints
These include REST endpoints, GraphQL resources, WebSocket endpoints, queues, and gRPC endpoints. Endpoint monitoring options are basically constrained by a combination of the frameworks you're using to build your endpoints and the infrastructure that your endpoints are deployed to.

## Measurement Types

### Latency
Latency is the time it takes to service a request. It's important to measure the latency of successful responses and also important to measure the latency of error responses. Think about it this way: slow errors are much worse than fast errors. If a request will eventually fail, it's better for it to fail fast and consume the fewest amount of lower-level resources possible.

### Traffic
Traffic is a measurement of demand. Every single request we measure, regardless of success or failure, is a measurement of a resource's traffic or demand.

### Rate
Rate is a measurement of successful responses and can also be called throughput. An example of a rate measurement is transactions per second, and we would assume successful transactions. To disambiguate between traffic and rate: traffic represents demand while rate represents throughput.

### Errors
Errors capture the rate of failure. A spike in errors over a short period of time might point to a serious anomaly with the resource being measured or an underlying resource. Remember that when we're discussing monitoring, we're not as concerned with individual failures but rather the rate of errors over time.

### Saturation
Saturation is the degree to which work goes unserviced. For example, work that starts piling up while waiting for a resource to become available is a measure of saturation. Imagine you're pushing to a stack—if you push more work than you pop, eventually the stack will overflow.

Saturation is basically an early warning of resource misallocation. In advanced cases, a saturation alert can be used to trigger self-healing, such as creating additional resources on demand to help relieve saturation.

### Utilization
Utilization is a measurement of resource allocation efficiency—basically the ratio that a resource's busy servicing work compared with waiting to perform work. Imagine a scenario in which we spawn a number of threads to service inbound requests to an endpoint. Those threads will wait in a pool for work to do. If we measure the amount of time that each thread is waiting compared with working, we can use this measurement to tune the pool of threads available.

Whereas saturation is concerned about resource starvation and cascading failures, utilization is concerned with efficiently provisioning resources and basically not wasting money. However, be careful when tuning resources too aggressively, especially if your system is prone to very bursty traffic. In a low utilization situation, if demand spikes faster than you can provision new resources, that will increase saturation.

We have to think about how all of these measurements and configuration options play together. Having a deep understanding of both saturation and utilization is basically at the heart of capacity planning.

### Amendments
Amendments are any type of change to a resource. Many types of amendments can be emitted as events, whether that's a hot patch applied to a service or a configuration change in production. Ideally, amendments in production systems are very low, and teams instead embrace concepts like immutable infrastructure and Phoenix-style deployments to basically avoid changing resources. But sometimes amendments are inevitable, and we can measure these.

### Anomalies
Anomalies are patterns of change for a single resource or a combination of resources. For instance, a rapid change in utilization combined with a decrease in throughput might not make sense and can trigger an anomaly event.

Anomalies can be used to detect complex issues like configuration drift, such as a cluster that becomes leaderless for a period of time. Anomalies are the most complicated measurements as they require an organization to have a clear picture of what behavior is expected in production and a very thorough way of monitoring against those expectations. In other words, if you're new to formal monitoring strategies, anomalies will probably be a second phase in your journey.

## Detailed Taxonomy Analysis

Each taxonomy we cover helps distill down the complexity of monitoring into a patterns-based approach. This really helps us focus the complexity of monitoring onto the pattern itself rather than an almost infinite variety of hodgepodge approaches to monitoring in production.

Imagine a standard in your organization where you decide to apply one of these taxonomies to a specific grouping of resources and then repeat that pattern until basically all resources are covered by monitoring. Now instead imagine an infinite combination of measurements across an infinite combination of resources. Which approach do you think will help unlock the efficiency of your Ops team?

### USE (Utilization, Saturation, Errors)
USE is the most established monitoring taxonomy, first published in ACM Queue in 2012. USE stands for utilization, saturation, and errors. USE is worth everyone researching; however, it's not the most popular taxonomy anymore, but it still has a lot of value for capacity planning as it clearly measures both utilization and saturation of a resource.

When you start planning out your monitoring strategy and you're thinking about capacity planning in the most simple way possible, maybe start with USE and see if it fits your needs.

### Google's Four Golden Signals
Google's Four Golden Signals is the newest emerging monitoring standard. It became popular in Site Reliability Engineering teams because of how strongly it's championed by Google. The golden signals are latency, traffic, errors, and saturation.

This is a really useful taxonomy for endpoints that may experience spikes or bursts of traffic, as with this model it's possible to correlate demand with saturation, which can aid everything from capacity planning to self-healing like provisioning additional cloud resources during a burst of demand. It's also detailed enough that it makes it well-suited for monitoring functional server components and low-level software resources, as golden signals can help with root cause analysis.

### RED (Rate, Errors, Duration)
RED is similar to the Four Golden Signals but without the saturation metric. RED stands for rate, errors, and duration. A Google employee named Tom Wilkie originated the RED method based on his experience at Google and his experience with the golden signals. Think of RED as a follow-up to the golden signals but purposefully simplified by dropping saturation and demand metrics and focusing on throughput.

It's a great choice for monitoring public endpoints like RESTful APIs. Visualizing throughput next to errors is a great way to keep an eye on symptoms of deeper problems. When lower-level resources start to misbehave, RED metrics will nearly always show a drop in throughput and a spike in errors.

While RED's simplicity makes it great to flag symptoms, it's less than ideal to learn about the root cause of symptoms. For this reason, it's not the best choice for monitoring functional server components and low-level software components. Its simplicity means that it may miss key details in a complex investigation.

### SAFE (Saturation, Amendments, Anomalies, Failures, Errors)
SAFE is a newer taxonomy that I've only seen published by a single company, Asserts.ai. However, it seems very well-suited to monitoring functional server components at high scale. SAFE stands for saturation, amendments, anomalies, failures, and errors.

It's one of the most comprehensive taxonomies out there for teams who are thinking of embracing advanced anomaly detection in the future. Amendments are particularly important events to track if you're managing a large fleet of mutable infrastructure. For instance, imagine we monitor tens of thousands of Linux servers. Any manual change to an individual server, even something as simple as patching a package, risks creating snowflake servers, which are basically modified resources that can't be brought to the current state through automation alone.

Visualizing amendments next to other measurements like saturation and errors can be a powerful way to debug production-breaking changes.

## Black Box and White Box Monitoring

In really complex environments where there can be a ton of resources to put under measurement, it can be really helpful to standardize on terminology. The terminology "white box" and "black box" monitoring can actually help us simplify overall dashboard design.

### Black Box Monitoring
Monitoring of public endpoints and other public interfaces that can be accessed directly by users is called black box monitoring. Basically, anything with a public interface is like a black box. Black box monitoring helps us spot symptoms. Symptoms might be a sign of deeper underlying issues. Publicly available endpoints are the main resource type that we perform black box monitoring on.

### White Box Monitoring
Monitoring the internal resources of a system component like CPU, memory, queues, and locks is what we call white box monitoring. White box monitoring points us towards the root cause of errors. Functional server components and low-level software resources that users or customers are unable to configure directly are the primary target of white box monitoring.

## Advice and Resources

Based on experience managing SRE teams and helping to monitor very complex production environments, here's some concrete advice:

### Taxonomy Recommendations
My personal preference is to use RED metrics for black box monitoring and Google's Four Golden Signals for white box monitoring. RED metrics on APIs will alert a team to a potential issue, and then the Four Golden Signals can help a team quickly diagnose the underlying issue.

### Focus on Percentiles, Not Averages
Averages are basically worthless. For instance, average latency over a five-minute window means nothing. Instead, focus on percentiles. A common approach is to alert on an upper bound percentile like P95, and this works well with many different measurement types.

Specifically for traffic and rate, also think about alerting on a lower bound. Imagine a rate measurement reaches below a certain threshold—this might be a symptom of something wrong with lower-level resources.

Guild Tenna Visual Systems goes one step further and recommends focusing on P99 rather than P95 when monitoring for latency, as it's what most of your users will eventually experience.

### Additional Resources
Steve Mushiro of Deloitte has an excellent free ebook on how to extract the golden signals from various parts of a cloud-based stack. This doesn't cover the gamut of everything you'll need to know about extracting all metrics from all resource types, but it will point you in the right direction.

## Conclusion

This has been a basic overview of monitoring strategies that are being used in production today to monitor very complex systems. The great thing about learning these taxonomies is they scale up and down—you can use these to monitor dozens or tens of thousands of nodes in production.

Solid operational visibility isn't accidental, but with these techniques, you'll be one step closer to achieving this. The benefits of enhanced operational visibility are well worth it, and monitoring is really at the cornerstone of solid operational visibility. These taxonomies are worth learning and putting into practice when the time is right.

---

*This guide provides the foundation for implementing effective monitoring strategies in complex production environments. Remember that monitoring is not just about collecting data—it's about creating actionable insights that help teams maintain reliable, scalable systems.*

_This document was last updated 11/25/2016 and is applicable to SDK version 2.5.0-beta2._

# Extending Heartbeat Properties in Application Insights #

The .NET Application Insights SDKs provide a new feature called Heartbeat. This feature
sends environment-specific information at pre-configured intervals. The feature will allow 
you to extend the properties that will be sent every interval, and will also allow you to 
indicate a healthy or unhealthy status for each interval of the heartbeat.

## A General Code Example ##

In order to add the extended properties of your choice to the Heartbeat as a developer
of an ITelemetryModule, you can follow the following pattern. Note that you must first add the
properties you want to include in the payload, and you can update (via set) the values and health
status of those properties for the duration of the application life cycle.

To add the payload properties, aquire the IHeartbeatPropertyManager module using the internal
`TelemetryModules` singleton. One way in which you could do this is from inside your 
`Initialize(TelemetryConfiguration telemetryConfig)` implementation method, and then iterate 
through the available modules looking for an implementation of `IHeartbeatPropertyManager`:

    using Microsoft.ApplicationInsights.Extensibility.Implementation.Tracing;
    ...
    // heartbeat property manager to add/update my heartbeat-delivered properties into:
    private IHeartbeatPropertyManager heartbeatManager= null;
    ...
    public void Initialize(TelemetryConfiguration configuration)
    {
        ...
        var modules = TelemetryModules.Instance;
        foreach (var telemetryModule in modules.Modules)
        {
            if (telemetryModule is IHeartbeatPropertyManager)
            {
                this.heartbeatManager = telemetryModule as IHeartbeatPropertyManager;
                break;
            }
        }
        ...

...now you will have a heartbeat property manager that you can work with (or not, remember to
test!). From here (but likely still within your `Initialize` method, you can Add the health
property fields that you want to see in the heartbeat payload for the duration of the
application's lifecycle.

    ...
    this.heartbeatManager.AddHeartbeatProperty(propertyName: "myHeartbeatProperty", propertyValue: this.MyHeartbeatProperty, isHealthy: true);
    ...

Outside of your `Initialize` method, you can update the values you've added by using the 
`SetHeartbeatProperty` method very simply. For instance, you can add a property called 
'myHeartbeatProperty' in the initialize method as above, and then from within a property elsewhere
in your class, you can update the value in the heartbeat payload as follows:

    public string MyHeartbeatProperty
    {
        get => this.myHeartbeatPropertyValue;

        set
        {
            this.myHeartbeatPropertyValue = value;
            if (this.heartbeatManager != null)
            {
                bool myPropIsHealthy = this.SomeTestForHealthStatus(this.myHeartbeatPropertyValue);
                this.heartbeatManager.SetHeartbeatProperty(propertyName: "myHeartbeatProperty", propertyValue: value, isHealthy: myPropIsHealthy);
            }
        }
    }

Using the above example you can add and update properties in the Heartbeat for the
duration of your application's life.

> **Note:** You may also set values for the `HeartbeatInterval` value. This is discouraged, as
your override of this value may adversely affect the consumer's ApplicationInsights.config
configuration in doing so.

You can also set values into the `ExcludedHeartbeatProperties` list if you find it pertinent to
do so.  Setting values into the `ExcludedHeartbeatProperties` is fine, as your module may provide
more detailed information about one of the many SDK-supplied default fields, and in these cases it
is better to remove the redundancy.

## Working Examples of Extending Properties ##

We've added a few TelemetryModules that can serve as working examples of extending the properties
sent with each heartbeat. These modules can be found in the [Web SDK repo][websdk-repo]. 

The first example uses only the `AddHeartbeatProperty` at initialize time, and never updates
the values stored for the heartbeat afterward. The [Azure Instance Metadata Telemetry module]
[azureims-mod] extracts values from the [Azure Instance Metadata Service][azure-ims] upon
initialization and if the service is accessible, they are added to the heartbeat properties for
the duration of the process runtime.

The second example is one that uses both the `AddHeartbeatProperty` and `SetHeartbeatProperty` 
methods, as it can be updated at any time during the process runtime. In the [Azure App Services]
[appsrv-mod] Telemetry module, the values stored in the environmnet are read upon initialization
and then a monitor re-reads those environment variables looking for any changes. Any subscriber
to this monitor will be notified if the environment variables change, and our [Azure App Services
Telemetry Module][appsrv-mod] is one such subscriber. If the module is not initialized it will use
`AddHeartbeatProperty` and after initialization, if the environment variables are updated, it will
use `SetHeartbeatProperty` to update the values in the heartbeat's properties.


[websdk-repo]: https://github.com/Microsoft/ApplicationInsights-dotnet-server/
[azureims-mod]: https://github.com/Microsoft/ApplicationInsights-dotnet-server/blob/develop/Src/WindowsServer/WindowsServer.Shared/AzureInstanceMetadataTelemetryModule.cs
[appsrv-mod]: https://github.com/Microsoft/ApplicationInsights-dotnet-server/blob/develop/Src/WindowsServer/WindowsServer.Shared/AppServicesHeartbeatTelemetryModule.cs
[azure-ims]: https://docs.microsoft.com/en-us/azure/virtual-machines/windows/instance-metadata-service
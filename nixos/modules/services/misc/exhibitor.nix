{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.exhibitor;

  exhibitorProperties = ''


  '';

  zookeeperConfig = ''
    dataDir=${cfg.zkDataDir}
    clientPort=${toString cfg.zkPort}
    autopurge.purgeInterval=${toString cfg.zkPurgeInterval}
    ${cfg.zkExtraConf}
    ${cfg.zkServers}
  '';

  s3Properties = ''
  com.netflix.exhibitor.s3.access-key-id="${if cfg.s3AccessKey then cfg.s3AccessKey else ""}"
  com.netflix.exhibitor.s3.access-secret-key="${if cfg.s3AccessSecretKey then cfg.s3AccessSecretKey else ""}"
  '';

  configDir = pkgs.buildEnv {
    name = "exhibitor-conf";
    paths = [
      (pkgs.writeTextDir ${cfg.s3Credentials} s3Properties)
      (pkgs.writeTextDir "log4j.properties" cfg.logging)
      (pkgs.writeTextDir "exhibitor.properties" exhibitorProperties)
    ];
  };

  in {

    options.services.exhibitor = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to enable exhibitor daemon.
        '';
      };

      port = mkOption {
        type = types.int;
        default = 8080;
        description = ''
          Port for the HTTP Server.
        '';
      };

      servo = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to expose ZK monitored
          statistics via JMX.
        '';
      };

      timeout = mkOption {
        type = types.int;
        default = 30000;
        description = ''
          Connection timeout in milliseconds for ZK connections.
        '';
      };

      configType = mkOption {
        type = types.str;
        default = "file";
        description = ''
          Defines the type of exhibitor configuration.
          Options: file, s3, zookeeper, none
        '';
      };

      configCheckms = mkOption {
        type = types.int;
        default = 30000;
        description = ''
          Time period in milliseconds to check the
          shared configuration updates.
        '';
      };

      hostName = mkOption {
        type = types.str;
        default = "localhost";
        description = ''
          Hostname to use for this JVM.
        '';
      };

      jqueryStyle = mkOption {
        type = types.str;
        default = "red";
        description = ''
          Styling used for the JQuery-based UI.
          Options: red, black, custom
        '';
      };

      logLines = mkOption {
        type = types.int;
        default = 1000;
        description = ''
          Max lines of logging to keep in memory
          for display.
        '';
      };

      nodeModification = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Whether to allow UI for nodes modification.
        '';
      };

      logging = mkOption {
        type = types.lines;
        default = ''
        log4j.rootLogger=INFO, console
        log4j.appender.console=org.apache.log4j.ConsoleAppender
        log4j.appender.console.layout=org.apache.log4j.PatternLayout
        log4j.appender.console.layout.ConversionPattern=%-5p %c %x %m [%t]%n
        '';
        description = ''
          Exhibitor logging configuration.
        '';
      };

      #### Zookeeper configuration

      zkDataDir = mkOption {
        type = types.path;
        default = "/var/lib/zookeeper";
        description = ''
          Data directory for Zookeeper
        '';
      };

      zkPort = mkOption {
        default = 2181;
        type = types.int;
        description = ''
          Zookeeper Client port.
        '';
      };

      zkPurgeInterval = mkOption {
        default = 1;
        type = types.int;
        description = ''
          The time interval in hours for which the purge task has to be triggered.
          Set to a positive integer (1 and above) to enable the auto purging.
        '';
      };

      zkExtraConf = mkOption {
        type = types.lines;
        default = ''
          initLimit=5
          syncLimit=2
          tickTime=2000
        '';
        description = ''
          Extra configuration for Zookeeper.
        '';
      };

      zkServers = mkOption {
        default = "";
        type = types.lines;
        example = ''
          server.0=host0:2888:3888
          server.1=host1:2888:3888
          server.2=host2:2888:3888
        '';
        description = ''
          Zookeeper Quorum Servers.
        '';
      };

      #### S3 related configuration for shared storage ####

      s3Credentials = mkOption {
        type = types.str;
        default = "s3.properties";
        description = ''
          Path of the credentials file used for
          s3backup or s3config.
        '';
      };

      s3Region = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          AWS Region for S3 bucket.
        '';
      };

      s3AccessKey = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          AWS Access Key
        '';
      };

      s3AccessSecretKey = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          AWS Access Secret Key
        '';
      };

      s3Config = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          S3 BucketName and key.
        '';
      };

      s3ConfigPrefix = mkOption {
        type = types.str;
        default = "exhibitor-";
        description = ''
          Prefix to use for values such as locks.
        '';
      };

      #### ZK related configuration for shared storage ####

      zkConfigConnect = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          Connection string for zk shared config storage.
        '';
      };

      zkConfigExhibitorPath = mkOption {
        type = types.path;
        default = "/";
        description = ''
          Used if the ZooKeeper shared config is also running Exhibitor.
          This is the URI path for the REST call.
        '';
      };

      zkConfigExhibitorPort = mkOption {
        type = types.nullOr types.int;
        default = 8080;
        description = ''
          Used if the ZooKeeper shared config is also running Exhibitor.
          This is the port that Exhibitor is listening on.
        '';
      };

      zkConfigPollms = mkOption {
        type = types.int;
        default = 10000;
        description = ''
          The period in milliseconds to check for changes in the
          config ensemble.
        '';
      };

      zkConfigRetry = mkOption {
        type = types.str;
        default = "1000:3";
        description = ''
          The retry values to use in the form
          sleep-ms:retry-qty.
        '';
      };

      zkConfigZPath = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          Base ZPath that Exhibitor should use.
          E.g: "/exhibitor/config"
        '';
      };

      #### Filesystem related configuration for shared storage ####

      fsConfigDir = mkOption {
        type = types.path;
        default = "/opt/app/grid/products/exhibitor2/bin";
        description = ''
          Directory to store Exhibitor properties (cannot be used with s3config).
          Exhibitor uses FS locks so you can specify a shared location so as to
          enable complete ensemble management.
        '';
      };

      fsConfigLockPrefix = mkOption {
        type = types.str;
        default = "exhibitor-lock-";
        description = ''
          Prefix for a locking mechanism.
        '';
      };

      fsConfigName = mkOption {
        type = types.str;
        default = "exhibitor-lock-";
        description = ''
          Name of the file to store config in.
        '';
      };

      fileSystemBackup = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Enables file system backup of ZooKeeper log files.
        '';
      };

      s3Backup = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Enables AWS S3 backup of ZooKeeper log files.
        '';
      };

    };

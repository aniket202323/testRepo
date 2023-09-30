create procedure dbo.spServer_CmnAddServices
@RequestedMode int = NULL,
@SimSkipFlag Int = 0
AS
-- Mode (1) Standard
-- Mode (2) Standard + ClientMgr
-- Mode (3) Standard + DataGenerator
-- Mode (4) Standard + ClientMgr + DataGenerator
-- Mode (5) DTM
Declare
  @Num int,
  @ActualMode int,
  @ClientMgrIsActive int,
  @MsgBusIsActive int,
  @ServiceIsActive int,
  @DataGeneratorIsActive int,
  @ReaderIsActive int,
  @EventMgrAutoStart int,
  @Msg nVarChar(255),
  @NumEmailGroups int,
  @ServicesNodename nVarChar(255),
  @NewServicesNodeName nVarChar(255),
  @ContentGeneratorIsActive int
SET @SimSkipFlag = Coalesce(@SimSkipFlag,0)
IF @SimSkipFlag != 1
BEGIN
 	 Select @NewServicesNodeName = ''
 	 -- This will happen if this SP is not being run from the installer or a bad server name
 	 if (Len(@NewServicesNodeName) > 15)
 	  	 Select @NewServicesNodeName = SUBSTRING(HOST_NAME(),1,15)
 	 IF NOT EXISTS(SELECT 1 FROM Site_Parameters Where (Parm_Id = 29) And (Hostname = ''))
 	 BEGIN
 	  	 INSERT INTO Site_Parameters(Parm_Id,HostName,Value) VALUES (29,'',@NewServicesNodeName)
 	 END
 	 ELSE
 	 BEGIN
 	  	 Select @ServicesNodeName = Value From Site_Parameters Where (Parm_Id = 29) And (Hostname = '')
 	  	 If (@NewServicesNodeName != @ServicesNodeName)
 	  	 Begin
 	  	  	 Update Site_Parameters Set Value = @NewServicesNodeName Where Parm_Id = 29 and Hostname = ''
 	  	 End
 	 END
 	 SELECT @ServicesNodeName = @NewServicesNodeName
 	 If (@ServicesNodeName Is NULL) Or (Len(@ServicesNodeName) = 0)
 	   Select @ServicesNodeName = HOST_NAME()
 	 Update Historians Set Hist_Servername = @@Servername Where Hist_Id = -1
END
If @RequestedMode Is Not NULL
  Select @ActualMode = @RequestedMode
Else
  Begin
    Select @MsgBusIsActive = NULL
    Select @ClientMgrIsActive = NULL
    Select @DataGeneratorIsActive = NULL
    Select @ReaderIsActive = NULL
    Select @MsgBusIsActive = Is_Active From CXS_Service Where Service_Id = 9    -- MessageBus / ConfigMgr
    Select @ClientMgrIsActive = Is_Active From CXS_Service Where Service_Desc = 'ClientMgr'
    Select @DataGeneratorIsActive = Is_Active From CXS_Service Where Service_Desc = 'DataGenerator'
    Select @ReaderIsActive = Is_Active From CXS_Service Where Service_Desc = 'Reader'
    If (@MsgBusIsActive Is NULL) Select @MsgBusIsActive = 0
    If (@ClientMgrIsActive Is NULL) Select @ClientMgrIsActive = 0
    If (@DataGeneratorIsActive Is NULL) Select @DataGeneratorIsActive = 0
    If (@ReaderIsActive Is NULL) Select @ReaderIsActive = 0
    If (@MsgBusIsActive = 0)
      Select @ActualMode = 1
    Else   
      If (@ReaderIsActive = 0)
        Select @ActualMode = 5
      Else
        If (@ClientMgrIsActive = 1) And (@DataGeneratorIsActive = 1)
          Select @ActualMode = 4
        Else
          If (@DataGeneratorIsActive = 1)
            Select @ActualMode = 3
          Else
            If (@ClientMgrIsActive = 1)
              Select @ActualMode = 2
            Else
              Select @ActualMode = 1
  End
Select @ContentGeneratorIsActive = NULL
Select @ContentGeneratorIsActive = Is_Active From CXS_Service Where Service_Id = 23
If (@ContentGeneratorIsActive Is NULL)
  Select @ContentGeneratorIsActive = 0
Delete From CXS_Leaf 
Delete From CXS_Route_Data 
Delete From CXS_Route 
Delete From CXS_Route_Group 
Delete From CXS_Service Where Service_Id in (3,12)
Delete From Bus_SubScriptions Where Message_Id Not In (Select Topic_Id From Topics)
Delete From Message_Types Where Message_Id Not In (Select Topic_Id From Topics)
Delete From Message_Properties
delete from ResultSetConfig
delete from ResultSetTypes
Delete from Performance_Statistics 
Delete from Performance_Counters
Delete from Performance_Objects
Select @Msg = 
  Case @ActualMode
    When 1 Then 'Adding Services [Standard]...'
    When 2 Then 'Adding Services [Standard]...'
    When 3 Then 'Adding Services [Standard]...'
    When 4 Then 'Adding Services [Standard]...'
    When 5 Then 'Adding Services [iDowntime]...'
    Else 'Adding Services [UNKNOWN]...'
End
Print @Msg
select @ServiceIsActive=1
select @EventMgrAutoStart=1
If (@ActualMode = 5)
 	 select @EventMgrAutoStart=0, @ServiceIsActive=0
Select @NumEmailGroups = NULL
Select @NumEmailGroups = Count(*) From Email_Groups
if (@NumEmailGroups Is NULL)
  Select @NumEmailGroups = 0
if (@NumEmailGroups <= 0)
  Select @NumEmailGroups = 0
if (@NumEmailGroups > 1)
  Select @NumEmailGroups = 1
IF @SimSkipFlag != 1
BEGIN
 	 exec spServer_CmnAddService  2,'PRDatabaseMgr' 	  	 ,'DatabaseMgr' 	  	  	 ,'Database Mgr'        	 , @ServicesNodeName 	 ,NULL 	  	  	  	  	  	  	 ,NULL , 1 	 ,1,1,1,15,15,30,3,1
 	 exec spServer_CmnAddService  4,'PREventMgr' 	  	  	  	 ,'EventMgr' 	  	  	  	  	 ,'Event Mgr'           	 , @ServicesNodeName 	 ,NULL 	  	  	  	  	  	  	 ,NULL , 1 	 ,1,@EventMgrAutoStart,@EventMgrAutoStart,15,15,30,5,1
 	 exec spServer_CmnAddService  5,'PRReader' 	  	  	  	  	 ,'Reader' 	  	  	  	  	  	 ,'Reader'              	 , @ServicesNodeName 	 ,NULL 	  	  	  	  	  	  	 ,NULL , 1 	 ,@ServiceIsActive,1,1,15,15,30,5,1
 	 exec spServer_CmnAddService  6,'PRWriter' 	  	  	  	  	 ,'Writer' 	  	  	  	  	  	 ,'Writer'              	 , @ServicesNodeName 	 ,NULL 	  	  	  	  	  	  	 ,NULL , 1 	 ,@ServiceIsActive,1,1,15,15,30,5,1
 	 exec spServer_CmnAddService  7,'PRSummaryMgr' 	  	  	 ,'SummaryMgr' 	  	  	  	 ,'Summary Mgr'         	 , @ServicesNodeName 	 ,NULL 	  	  	  	  	  	  	 ,NULL , 1 	 ,@ServiceIsActive,1,1,15,15,30,5,1
 	 exec spServer_CmnAddService  8,'PRStubber' 	  	  	  	 ,'Stubber' 	  	  	  	  	 ,'Stubber'        	  	  	  	 , @ServicesNodeName 	 ,NULL 	  	  	  	  	  	  	 ,NULL , 	 1 	 ,@ServiceIsActive,1,1,15,15,30,3,1
 	 exec spServer_CmnAddService  9,'PRConfigMgr' 	  	  	 ,'ConfigMgr' 	  	  	  	 ,'Config Manager'    	  	 , @ServicesNodeName 	 ,NULL 	   	   	  	  	  	  	 ,NULL , 	 1 	 ,1,1,1,15,15,25,5,1
 	 exec spServer_CmnAddService 11,'PRSiteSpecific' 	  	 ,'SiteSpecificInterface','Site Specific'    , @ServicesNodeName 	 ,NULL 	  	  	  	  	  	  	 ,NULL , 0 	 ,0,1,1,15,15,30,3,0
 	 exec spServer_CmnAddService 14,'PRGateway' 	  	  	  	 ,'Gateway' 	  	  	  	  	 ,'Gateway'             	 , @ServicesNodeName 	 ,@ServicesNodeName,12294, 1 	 ,1,1,1,15,15,30,3,1
 	 exec spServer_CmnAddService 15,'PRProficyMgr' 	  	  	 ,'PlantAppsMgr' 	  	  	 ,'PlantApps Manager' 	  	 , @ServicesNodeName 	 ,@ServicesNodeName,12293, 1 	 ,0,0,0, 0, 0, 0,0,1
 	 exec spServer_CmnAddService 16,'PREmailEngine' 	  	 ,'EmailEngine' 	  	  	 ,'Email Engine' 	  	  	  	  	 , @ServicesNodeName 	 ,NULL 	  	  	  	  	  	  	 ,NULL , @NumEmailGroups,1,1,1,15,15,30,3,1
 	 exec spServer_CmnAddService 17,'PRAlarmMgr' 	  	  	  	 ,'AlarmMgr' 	  	  	  	  	 ,'Alarm Manager' 	  	  	  	 , @ServicesNodeName 	 ,NULL 	  	  	  	  	  	  	 ,NULL , 1 	 ,@ServiceIsActive,1,1,15,15,30,3,1
 	 exec spServer_CmnAddService 18,'PRFTPEngine' 	  	  	 ,'FTPEngine' 	  	  	  	 ,'FTP Engine' 	  	  	  	  	  	 , @ServicesNodeName 	 ,NULL 	  	  	  	  	  	  	 ,NULL , 1 	 ,@ServiceIsActive,1,1,15,15,30,3,1
 	 exec spServer_CmnAddService 19,'PRCalculationMgr' 	 ,'CalculationMgr' 	  	 ,'Calculation Manager' 	 , @ServicesNodeName 	 ,NULL 	  	  	  	  	  	  	 ,NULL , 1 	 ,@ServiceIsActive,1,1,15,15,30,3,1
 	 exec spServer_CmnAddService 20,'PRPrintServer' 	  	 ,'PrintServer' 	  	  	 ,'Print Server'        	 , @ServicesNodeName 	 ,NULL 	  	  	  	  	  	  	 ,NULL , 1 	 ,@ServiceIsActive,1,1,15,15,30,3,1
 	 exec spServer_CmnAddService 21,'PRRDS' 	  	  	  	  	  	 ,'RDS' 	  	  	  	  	  	  	 ,'Remote Data Service'  	 , @ServicesNodeName 	 ,NULL 	  	  	  	  	  	  	 ,12299, 1 	 ,@ServiceIsActive,1,1,15,15,20,3,1
 	 exec spServer_CmnAddService 22,'PRScheduleMgr' 	  	 ,'ScheduleMgr' 	  	  	 ,'Schedule Mgr'  	       	 , @ServicesNodeName 	 ,NULL 	  	  	  	  	  	  	 ,NULL,  1 	 ,@ServiceIsActive,1,1,15,15,30,3,1
 	 exec spServer_CmnAddService 23,'PRContentGenerator','ContentGenerator','WebPart Content Generator',@ServicesNodeName,NULL 	  	  	  	  	  	 ,NULL,  @ContentGeneratorIsActive 	 ,1,1,1,15,15,30,3,1
 	 exec spServer_CmnAddService 24,'PRRouter' 	  	  	  	  	 ,'Router' 	  	  	  	  	  	 ,'Message Router'    	  	 , @ServicesNodeName 	 ,NULL 	   	   	  	  	  	  	 ,NULL , 	 1 	 ,1,1,1,15,15,20,1,1
 	 exec spServer_CmnAddService 25,'Proficy.PlantApps.MessageBridge', 'MessageBridge', 'Plant Apps Message Bridge', @ServicesNodeName, NULL, NULL, 1, 1, 1, 1, 15, 15, 100, 1, 1
END
SET IDENTITY_INSERT CXS_Route_Group ON
INSERT CXS_Route_Group(RG_Id, RG_Desc) VALUES( 2, 'Database Mgr')
INSERT CXS_Route_Group(RG_Id, RG_Desc) VALUES( 4, 'Event Mgr')
INSERT CXS_Route_Group(RG_Id, RG_Desc) VALUES( 5, 'Reader')
INSERT CXS_Route_Group(RG_Id, RG_Desc) VALUES( 6, 'Writer')
INSERT CXS_Route_Group(RG_Id, RG_Desc) VALUES( 7, 'Summary Mgr')
INSERT CXS_Route_Group(RG_Id, RG_Desc) VALUES( 8, 'Stubber')
INSERT CXS_Route_Group(RG_Id, RG_Desc) VALUES(10, 'Site Specific')
INSERT CXS_Route_Group(RG_Id, RG_Desc) VALUES(12, 'Gateway')
INSERT CXS_Route_Group(RG_Id, RG_Desc) VALUES(13, 'PlantAppsMgr')
INSERT CXS_Route_Group(RG_Id, RG_Desc) VALUES(14, 'AlarmMgr')
INSERT CXS_Route_Group(RG_Id, RG_Desc) VALUES(15, 'CalculationMgr')
INSERT CXS_Route_Group(RG_Id, RG_Desc) VALUES(16, 'ScheduleMgr')
INSERT CXS_Route_Group(RG_Id, RG_Desc) VALUES(17, 'ContentGenerator')
INSERT CXS_Route_Group(RG_Id, RG_Desc) VALUES(20, 'RabbitMQMessageBridge')
INSERT CXS_Route_Group(RG_Id, RG_Desc) VALUES(21, 'KafkaMessageBridge')
SET IDENTITY_INSERT CXS_Route_Group OFF
INSERT CXS_Leaf(Service_Id, RG_Id, Memory_List_Size, Permenant, Buffer_To_Disk) VALUES( 2,  2, 100, 1, 1)
INSERT CXS_Leaf(Service_Id, RG_Id, Memory_List_Size, Permenant, Buffer_To_Disk) VALUES( 4,  4, 100, 1, 1)
INSERT CXS_Leaf(Service_Id, RG_Id, Memory_List_Size, Permenant, Buffer_To_Disk) VALUES( 5,  5, 100, 1, 1)
INSERT CXS_Leaf(Service_Id, RG_Id, Memory_List_Size, Permenant, Buffer_To_Disk) VALUES( 6,  6, 100, 1, 1)
INSERT CXS_Leaf(Service_Id, RG_Id, Memory_List_Size, Permenant, Buffer_To_Disk) VALUES( 7,  7, 100, 1, 1)
INSERT CXS_Leaf(Service_Id, RG_Id, Memory_List_Size, Permenant, Buffer_To_Disk) VALUES( 8,  8, 100, 1, 1)
INSERT CXS_Leaf(Service_Id, RG_Id, Memory_List_Size, Permenant, Buffer_To_Disk) VALUES(11, 10, 100, 1, 1)
INSERT CXS_Leaf(Service_Id, RG_Id, Memory_List_Size, Permenant, Buffer_To_Disk) VALUES(14, 12, 100, 1, 1)
INSERT CXS_Leaf(Service_Id, RG_Id, Memory_List_Size, Permenant, Buffer_To_Disk) VALUES(15, 13, 100, 1, 1)
INSERT CXS_Leaf(Service_Id, RG_Id, Memory_List_Size, Permenant, Buffer_To_Disk) VALUES(17, 14, 100, 1, 1)
INSERT CXS_Leaf(Service_Id, RG_Id, Memory_List_Size, Permenant, Buffer_To_Disk) VALUES(19, 15, 100, 1, 1)
INSERT CXS_Leaf(Service_Id, RG_Id, Memory_List_Size, Permenant, Buffer_To_Disk) VALUES(22, 16, 100, 1, 1)
INSERT CXS_Leaf(Service_Id, RG_Id, Memory_List_Size, Permenant, Buffer_To_Disk) VALUES(23, 17, 100, 0, 0)
INSERT CXS_Leaf(Service_Id, RG_Id, Memory_List_Size, Permenant, Buffer_To_Disk) VALUES(25, 20, 100, 1, 1)
INSERT CXS_Leaf(Service_Id, RG_Id, Memory_List_Size, Permenant, Buffer_To_Disk) VALUES(25, 21, 100, 1, 1)
SET IDENTITY_INSERT CXS_Route ON
INSERT CXS_Route(Route_Id, Route_Desc, Should_Buffer) VALUES( 1, 'Pre Column',1)
INSERT CXS_Route(Route_Id, Route_Desc, Should_Buffer) VALUES( 2, 'Post Column',1)
INSERT CXS_Route(Route_Id, Route_Desc, Should_Buffer) VALUES( 3, 'Lazy Column',1)
INSERT CXS_Route(Route_Id, Route_Desc, Should_Buffer) VALUES( 4, 'Pre Grade',1)
INSERT CXS_Route(Route_Id, Route_Desc, Should_Buffer) VALUES( 5, 'Post Grade',1)
INSERT CXS_Route(Route_Id, Route_Desc, Should_Buffer) VALUES( 6, 'Pre Master',1)
INSERT CXS_Route(Route_Id, Route_Desc, Should_Buffer) VALUES( 7, 'Post Master',1)
INSERT CXS_Route(Route_Id, Route_Desc, Should_Buffer) VALUES( 8, 'Lazy Master',1)
INSERT CXS_Route(Route_Id, Route_Desc, Should_Buffer) VALUES( 9, 'Pre Timed',1)
INSERT CXS_Route(Route_Id, Route_Desc, Should_Buffer) VALUES(10, 'Post Timed',1)
INSERT CXS_Route(Route_Id, Route_Desc, Should_Buffer) VALUES(11, 'Pre Waste',1)
INSERT CXS_Route(Route_Id, Route_Desc, Should_Buffer) VALUES(12, 'Post Waste',1)
INSERT CXS_Route(Route_Id, Route_Desc, Should_Buffer) VALUES(13, 'Pre Variable',1)
INSERT CXS_Route(Route_Id, Route_Desc, Should_Buffer) VALUES(14, 'Post Variable',1)
INSERT CXS_Route(Route_Id, Route_Desc, Should_Buffer) VALUES(15, 'No Archive Variable',1)
INSERT CXS_Route(Route_Id, Route_Desc, Should_Buffer) VALUES(16, 'CMGR Control',1)
INSERT CXS_Route(Route_Id, Route_Desc, Should_Buffer) VALUES(17, 'RDR Control',1)
INSERT CXS_Route(Route_Id, Route_Desc, Should_Buffer) VALUES(18, 'Pre Production',1)
INSERT CXS_Route(Route_Id, Route_Desc, Should_Buffer) VALUES(19, 'Post Production',1)
INSERT CXS_Route(Route_Id, Route_Desc, Should_Buffer) VALUES(20, 'Lazy Production',1)
INSERT CXS_Route(Route_Id, Route_Desc, Should_Buffer) VALUES(21, 'Lazy Waste',1)
INSERT CXS_Route(Route_Id, Route_Desc, Should_Buffer) VALUES(22, 'Lazy Timed',1)
INSERT CXS_Route(Route_Id, Route_Desc, Should_Buffer) VALUES(23, 'Bus Control',1)
INSERT CXS_Route(Route_Id, Route_Desc, Should_Buffer) VALUES(24, 'Bus Info',1)
INSERT CXS_Route(Route_Id, Route_Desc, Should_Buffer) VALUES(25, 'Topic',0)
INSERT CXS_Route(Route_Id, Route_Desc, Should_Buffer) VALUES(26, 'Subscribe Info',0)
INSERT CXS_Route(Route_Id, Route_Desc, Should_Buffer) VALUES(27, 'Subscribe Query',1)
INSERT CXS_Route(Route_Id, Route_Desc, Should_Buffer) VALUES(28, 'Pre User Def Event', 1)
INSERT CXS_Route(Route_Id, Route_Desc, Should_Buffer) VALUES(29, 'Post User Def Event', 1)
INSERT CXS_Route(Route_Id, Route_Desc, Should_Buffer) VALUES(30, 'Pre Alarm', 1)
INSERT CXS_Route(Route_Id, Route_Desc, Should_Buffer) VALUES(31, 'Post Alarm', 1)
INSERT CXS_Route(Route_Id, Route_Desc, Should_Buffer) VALUES(32, 'Pre Event Detail', 1)
INSERT CXS_Route(Route_Id, Route_Desc, Should_Buffer) VALUES(33, 'Post Event Detail', 1)
INSERT CXS_Route(Route_Id, Route_Desc, Should_Buffer) VALUES(34, 'Pre Event Component', 1)
INSERT CXS_Route(Route_Id, Route_Desc, Should_Buffer) VALUES(35, 'Post Event Component', 1)
INSERT CXS_Route(Route_Id, Route_Desc, Should_Buffer) VALUES(36, 'Pre PE Input Event', 1)
INSERT CXS_Route(Route_Id, Route_Desc, Should_Buffer) VALUES(37, 'Post PE Input Event', 1)
INSERT CXS_Route(Route_Id, Route_Desc, Should_Buffer) VALUES(38, 'Pre Container', 1)
INSERT CXS_Route(Route_Id, Route_Desc, Should_Buffer) VALUES(39, 'Post Container', 1)
INSERT CXS_Route(Route_Id, Route_Desc, Should_Buffer) VALUES(40, 'Pre Defect Detail', 1)
INSERT CXS_Route(Route_Id, Route_Desc, Should_Buffer) VALUES(41, 'Post Defect Detail', 1)
INSERT CXS_Route(Route_Id, Route_Desc, Should_Buffer) VALUES(42, 'Historian Write', 1)
INSERT CXS_Route(Route_Id, Route_Desc, Should_Buffer) VALUES(43, 'Pre Production Plan', 1)
INSERT CXS_Route(Route_Id, Route_Desc, Should_Buffer) VALUES(44, 'Post Production Plan', 1)
INSERT CXS_Route(Route_Id, Route_Desc, Should_Buffer) VALUES(45, 'Pre Production Plan Starts', 1)
INSERT CXS_Route(Route_Id, Route_Desc, Should_Buffer) VALUES(46, 'Post Production Plan Starts', 1)
INSERT CXS_Route(Route_Id, Route_Desc, Should_Buffer) VALUES(47, 'Pre Production Setup', 1)
INSERT CXS_Route(Route_Id, Route_Desc, Should_Buffer) VALUES(48, 'Post Production Setup', 1)
INSERT CXS_Route(Route_Id, Route_Desc, Should_Buffer) VALUES(49, 'Pre Production Stats', 1)
INSERT CXS_Route(Route_Id, Route_Desc, Should_Buffer) VALUES(50, 'Post Production Stats', 1)
INSERT CXS_Route(Route_Id, Route_Desc, Should_Buffer) VALUES(51, 'Pre PrdExec Path Unit Starts', 1)
INSERT CXS_Route(Route_Id, Route_Desc, Should_Buffer) VALUES(52, 'Post PrdExec Path Unit Starts', 1)
INSERT CXS_Route(Route_Id, Route_Desc, Should_Buffer) VALUES(53, 'Historian Read', 1)
INSERT CXS_Route(Route_Id, Route_Desc, Should_Buffer) VALUES(54, 'Pre Non Productive Time', 1)
INSERT CXS_Route(Route_Id, Route_Desc, Should_Buffer) VALUES(55, 'Post Non Productive Time', 1)
INSERT CXS_Route(Route_Id, Route_Desc, Should_Buffer) VALUES(56, 'Lazy Non Productive Time', 1)
INSERT CXS_Route(Route_Id, Route_Desc, Should_Buffer) VALUES(57, 'Pre Crew Schedule', 1)
INSERT CXS_Route(Route_Id, Route_Desc, Should_Buffer) VALUES(58, 'Post Crew Schedule', 1)
INSERT CXS_Route(Route_Id, Route_Desc, Should_Buffer) VALUES(59, 'Pre Event And Detail', 1)
INSERT CXS_Route(Route_Id, Route_Desc, Should_Buffer) VALUES(60, 'Post Event And Detail', 1)
INSERT CXS_Route(Route_Id, Route_Desc, Should_Buffer) VALUES(61, 'Pre Simulate Calculations', 0)
INSERT CXS_Route(Route_Id, Route_Desc, Should_Buffer) VALUES(62, 'Post Simulate Calculations', 0)
SET IDENTITY_INSERT CXS_Route OFF
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(2,  1) 	 -- DatabaseMgr: Pre Column
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(2,  4) 	 -- DatabaseMgr: Pre Grade
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(2,  6) 	 -- DatabaseMgr: Pre Master
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(2,  9) 	 -- DatabaseMgr: Pre Timed
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(2, 11) 	 -- DatabaseMgr: Pre Waste
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(2, 13) 	 -- DatabaseMgr: Pre Variable
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(2, 18) 	 -- DatabaseMgr: Pre Production
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(2, 23) 	 -- DatabaseMgr: Bus Control
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(2, 28) 	 -- DatabaseMgr: Pre User Def Event
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(2, 32) 	 -- DatabaseMgr: Pre Event Detail
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(2, 34) 	 -- DatabaseMgr: Pre Event Component
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(2, 36) 	 -- DatabaseMgr: Pre PE Input Event
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(2, 38) 	 -- DatabaseMgr: Pre Container
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(2, 40) 	 -- DatabaseMgr: Pre Defect Detail
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(2, 43) 	 -- DatabaseMgr: Pre Production Plan
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(2, 45) 	 -- DatabaseMgr: Pre Production Plan Starts
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(2, 47) 	 -- DatabaseMgr: Pre Production Setup
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(2, 49) 	 -- DatabaseMgr: Pre Production Stats
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(2, 51) 	 -- DatabaseMgr: Pre PrdExec Path Unit Starts
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(2, 54) 	 -- DatabaseMgr: Pre Non Productive Time
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(2, 57) 	 -- DatabaseMgr: Pre Crew Schedule
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(2, 59) 	 -- DatabaseMgr: Pre Event And Detail
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(2, 14) 	 -- DatabaseMgr: Post Variable
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(2, 35) 	 -- DatabaseMgr: Post Event Component
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(2, 33) 	 -- DatabaseMgr: Post Event Detail
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(4,  7) 	 -- EventMgr:  	 Post Master
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(4,  8) 	 -- EventMgr:  	 Lazy Master
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(4, 14) 	 -- EventMgr:  	 Post Variable
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(4, 12) 	 -- EventMgr: 	 Post Waste
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(4, 23) 	 -- EventMgr:   	 Bus Control
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(5, 14) 	 -- Reader:  	 Post Variable
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(5, 23) 	 -- Reader:  Bus Control
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(5, 53) 	 -- Reader:  	 Historian Read
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(6, 14) 	 -- Writer:  	 Post Variable
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(6, 23) 	 -- Writer:  Bus Control
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(6, 42) 	 -- Writer:  	 Historian Write
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(7, 14) 	 -- SummaryMgr:  	 Post Variable
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(7, 23) 	 -- SummaryMgr:  Bus Control
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(8,  2) 	 -- Stubber:  	 Post Column
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(8, 14) 	 -- Stubber:  	 Post Variable
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(8, 23) 	 -- Stubber:   Bus Control
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(12, 1) 	 -- Gateway:  	 Pre Column
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(12, 2) 	 -- Gateway:  	 Post Column
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(12, 3) 	 -- Gateway:  	 Lazy Column
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(12, 4) 	 -- Gateway:  	 Post Grade
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(12, 5) 	 -- Gateway:  	 Post Grade
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(12, 6) 	 -- Gateway:  	 Pre Master
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(12, 7) 	 -- Gateway:  	 Post Master
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(12, 8) 	 -- Gateway:  	 Lazy Master
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(12, 9) 	 -- Gateway:  	 Pre Timed
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(12,10) 	 -- Gateway:  	 Post Timed
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(12,11) 	 -- Gateway:  	 Pre Waste
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(12,12) 	 -- Gateway:  	 Post Waste
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(12,13) 	 -- Gateway:  	 Pre Variable
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(12,14) 	 -- Gateway:  	 Post Variable
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(12,15) 	 -- Gateway:  	 No Archive Variable
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(12,16) 	 -- Gateway:  	 CMGR Control
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(12,18) 	 -- Gateway:  	 Pre Production
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(12,19) 	 -- Gateway:  	 Post Production
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(12,21) 	 -- Gateway:  	 Lazy Waste
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(12,22) 	 -- Gateway:  	 Lazy Timed
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(12,23) 	 -- Gateway:   Bus Control
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(12,24) 	 -- Gateway:  	 Bus Info
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(12,25) 	 -- Gateway:  	 Production Overview
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(12,27) 	 -- Gateway:  	 Subscribe Query
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(12,29) 	 -- Gateway:  	 Post User Def Event
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(12,31) 	 -- Gateway:  	 Post Alarm
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(12,32) 	 -- Gateway:  	 Pre Event Detail
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(12,33) 	 -- Gateway:  	 Post Event Detail
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(12,34) 	 -- Gateway:  	 Pre Event Component
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(12,35) 	 -- Gateway:  	 Post Event Component
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(12,36) 	 -- Gateway:  	 Pre Event Detail
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(12,37) 	 -- Gateway:  	 Post Event Detail
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(12,39) 	 -- Gateway:  	 Post Container
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(12,40) 	 -- Gateway:  	 Pre Defect Detail
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(12,41) 	 -- Gateway:  	 Post Defect Detail
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(12,43) 	 -- Gateway:  	 Pre Production Plan
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(12,44) 	 -- Gateway:  	 Post Production Plan
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(12,45) 	 -- Gateway:  	 Pre Production Plan Starts
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(12,46) 	 -- Gateway:  	 Post Production Plan Starts
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(12,47) 	 -- Gateway:  	 Pre Production Setup
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(12,48) 	 -- Gateway:  	 Post Production Setup
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(12,49) 	 -- Gateway:  	 Pre Production Stats
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(12,50) 	 -- Gateway:  	 Post Production Stats
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(12,51) 	 -- Gateway:  	 Pre PrdExec Path Unit Starts
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(12,52) 	 -- Gateway:  	 Post PrdExec Path Unit Starts
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(12, 54) 	 -- Gateway: 	  	 Pre Non Productive Time
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(12, 55) 	 -- Gateway: 	  	 Post Non Productive Time
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(12, 56) 	 -- Gateway: 	  	 Lazy Non Productive Time
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(12, 57) 	 -- Gateway:   Pre Crew Schedule
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(12, 58) 	 -- Gateway:   Post Crew Schedule
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(12, 59) 	 -- Gateway:   Pre Event And Detail
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(12, 60) 	 -- Gateway:   Post Event And Detail
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(12, 62) 	 -- Gateway:   Post Simulate Calculations
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(14,14) 	 -- AlarmMgr:  	  	 Post Variable
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(14, 5) 	 -- AlarmMgr:  	  	 Post Grade 
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(14,23) 	 -- AlarmMgr:    Bus Control
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(14,30) 	 -- AlarmMgr:  	  	 Pre Alarm
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(15,14) 	 -- CalculationMgr: 	 Post Variable
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(15,23) 	 -- CalculationMgr:  Bus Control
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(15,26) 	 -- CalculationMgr: 	 Subscription
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(15,35) 	 -- CalculationMgr:  	 Post Event Component
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(15,61) 	 -- CalculationMgr:  	 Pre Simulate Calculations
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(16, 7) 	 -- ScheduleMgr:  	 Post Master
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(16,10) 	 -- ScheduleMgr:  	 Post Timed
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(16,12) 	 -- ScheduleMgr:  	 Post Waste
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(16,14) 	 -- ScheduleMgr:  	 Post Variable
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(16,23) 	 -- ScheduleMgr:   Bus Control
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(16,33) 	 -- ScheduleMgr:  	 Post Event Det
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(16,44) 	 -- ScheduleMgr:  	 Post Production Plan
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(16,46) 	 -- ScheduleMgr:  	 Post Production Plan Starts
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(16,48) 	 -- ScheduleMgr:  	 Post Production Setup
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(16,50) 	 -- ScheduleMgr:  	 Post Production Stats
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(17, 23) 	 -- ContentGenerator:  Bus Control
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(17, 14) -- ContentGenerator: 	 Post Variable
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(17, 5)  -- ContentGenerator: 	 Post GRADE
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(17, 7)  -- ContentGenerator: 	 Post Master
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(20, 2) 	 -- RabbitMQMessageBridge:  	 Post Column
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(20, 5) 	 -- RabbitMQMessageBridge:  	 Post Grade
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(20, 7) 	 -- RabbitMQMessageBridge:  	 Post Master (Production)
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(20,10) 	 -- RabbitMQMessageBridge:  	 Post Timed (Downtime)
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(20,12) 	 -- RabbitMQMessageBridge:  	 Post Waste
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(20,14) 	 -- RabbitMQMessageBridge:  	 Post Variable
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(20,25) 	 -- RabbitMQMessageBridge:  	 Topics - (Activities)
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(20,29) 	 -- RabbitMQMessageBridge:  	 Post User Def Event
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(20,31) 	 -- RabbitMQMessageBridge:  	 Post Alarm
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(20,33) 	 -- RabbitMQMessageBridge:  	 Post Event Detail
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(20,35) 	 -- RabbitMQMessageBridge:  	 Post Event Component
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(20,37) 	 -- RabbitMQMessageBridge:  	 Post PE Input Event
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(20,44) 	 -- RabbitMQMessageBridge:  	 Post Production Plan
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(20,46) 	 -- RabbitMQMessageBridge:  	 Post Production Plan Start
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(20,50) 	 -- RabbitMQMessageBridge:  	 Post Production Stats
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(20,55) 	 -- RabbitMQMessageBridge:  	 Post Non Productive Time
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(20, 1) 	 -- RabbitMQMessageBridge:  	 Pre Column
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(20, 4) 	 -- RabbitMQMessageBridge:  	 Pre Grade
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(20, 6) 	 -- RabbitMQMessageBridge:  	 Pre Master (Production)
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(20, 9) 	 -- RabbitMQMessageBridge:  	 Pre Timed (Downtime)
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(20,11) 	 -- RabbitMQMessageBridge:  	 Pre Waste
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(20,13) 	 -- RabbitMQMessageBridge:  	 Pre Variable
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(20,28) 	 -- RabbitMQMessageBridge:  	 Pre User Def Event
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(20,30) 	 -- RabbitMQMessageBridge:  	 Pre Alarm
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(20,32) 	 -- RabbitMQMessageBridge:  	 Pre Event Detail
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(20,34) 	 -- RabbitMQMessageBridge:  	 Pre Event Component
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(20,36) 	 -- RabbitMQMessageBridge:  	 Pre PE Input Event
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(20,43) 	 -- RabbitMQMessageBridge:  	 Pre Production Plan
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(20,45) 	 -- RabbitMQMessageBridge:  	 Pre Production Plan Start
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(20,49) 	 -- RabbitMQMessageBridge:  	 Pre Production Stats
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(20,54) 	 -- RabbitMQMessageBridge:  	 Pre Non Productive Time
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(21, 2) 	 -- KafkaMessageBridge:  	 Post Column
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(21, 5) 	 -- KafkaMessageBridge:  	 Post Grade
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(21, 7) 	 -- KafkaMessageBridge:  	 Post Master (Production)
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(21,10) 	 -- KafkaMessageBridge:  	 Post Timed (Downtime)
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(21,12) 	 -- KafkaMessageBridge:  	 Post Waste
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(21,14) 	 -- KafkaMessageBridge:  	 Post Variable
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(21,25) 	 -- KafkaMessageBridge:  	 Topics - (Activities)
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(21,29) 	 -- KafkaMessageBridge:  	 Post User Def Event
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(21,31) 	 -- KafkaMessageBridge:  	 Post Alarm
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(21,33) 	 -- KafkaMessageBridge:  	 Post Event Detail
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(21,35) 	 -- KafkaMessageBridge:  	 Post Event Component
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(21,37) 	 -- KafkaMessageBridge:  	 Post PE Input Event
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(21,44) 	 -- KafkaMessageBridge:  	 Post Production Plan
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(21,46) 	 -- KafkaMessageBridge:  	 Post Production Plan Start
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(21,50) 	 -- KafkaMessageBridge:  	 Post Production Stats
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(21,55) 	 -- KafkaMessageBridge:  	 Post Non Productive Time
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(21, 1) 	 -- KafkaMessageBridge:  	 Pre Column
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(21, 4) 	 -- KafkaMessageBridge:  	 Pre Grade
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(21, 6) 	 -- KafkaMessageBridge:  	 Pre Master (Production)
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(21, 9) 	 -- KafkaMessageBridge:  	 Pre Timed (Downtime)
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(21,11) 	 -- KafkaMessageBridge:  	 Pre Waste
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(21,13) 	 -- KafkaMessageBridge:  	 Pre Variable
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(21,28) 	 -- KafkaMessageBridge:  	 Pre User Def Event
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(21,30) 	 -- KafkaMessageBridge:  	 Pre Alarm
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(21,32) 	 -- KafkaMessageBridge:  	 Pre Event Detail
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(21,34) 	 -- KafkaMessageBridge:  	 Pre Event Component
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(21,36) 	 -- KafkaMessageBridge:  	 Pre PE Input Event
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(21,43) 	 -- KafkaMessageBridge:  	 Pre Production Plan
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(21,45) 	 -- KafkaMessageBridge:  	 Pre Production Plan Start
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(21,49) 	 -- KafkaMessageBridge:  	 Pre Production Stats
INSERT CXS_Route_Data(RG_Id, Route_Id) VALUES(21,54) 	 -- KafkaMessageBridge:  	 Pre Non Productive Time
Insert Into Message_Types(Message_Id,Description) Values(0 	 ,'Undefined')
Insert Into Message_Types(Message_Id,Description) Values(1 	 ,'Dynamic Identification')
Insert Into Message_Types(Message_Id,Description) Values(2 	 ,'Generic')
Insert Into Message_Types(Message_Id,Description) Values(3 	 ,'Variable Result')
Insert Into Message_Types(Message_Id,Description) Values(4 	 ,'Production Event')
Insert Into Message_Types(Message_Id,Description) Values(5 	 ,'Product Change')
Insert Into Message_Types(Message_Id,Description) Values(6 	 ,'Delay')
Insert Into Message_Types(Message_Id,Description) Values(7 	 ,'Waste')
Insert Into Message_Types(Message_Id,Description) Values(8 	 ,'Column')
Insert Into Message_Types(Message_Id,Description) Values(9 	 ,'Bus Control')
Insert Into Message_Types(Message_Id,Description) Values(10 	 ,'Bus Info')
Insert Into Message_Types(Message_Id,Description) Values(11 	 ,'Identification')
Insert Into Message_Types(Message_Id,Description) Values(12 	 ,'Client Acceptance')
Insert Into Message_Types(Message_Id,Description) Values(13 	 ,'Client Shutdown')
Insert Into Message_Types(Message_Id,Description) Values(14 	 ,'Event Detail')
Insert Into Message_Types(Message_Id,Description) Values(15 	 ,'Subscription')
Insert Into Message_Types(Message_Id,Description) Values(17 	 ,'Alarm')
Insert Into Message_Types(Message_Id,Description) Values(18 	 ,'User Defined Event')
Insert Into Message_Types(Message_Id,Description) Values(19 	 ,'Event Component')
Insert Into Message_Types(Message_Id,Description) Values(20 	 ,'Container')
Insert Into Message_Types(Message_Id,Description) Values(21 	 ,'Input Event')
Insert Into Message_Types(Message_Id,Description) Values(22 	 ,'Defect Detail')
Insert Into Message_Types(Message_Id,Description) Values(24 	 ,'Validate User')
Insert Into Message_Types(Message_Id,Description) Values(25 	 ,'Historian Write')
Insert Into Message_Types(Message_Id,Description) Values(26 	 ,'Prd Exec Path Unit Start')
Insert Into Message_Types(Message_Id,Description) Values(27 	 ,'Production Setup')
Insert Into Message_Types(Message_Id,Description) Values(28 	 ,'Production Plan')
Insert Into Message_Types(Message_Id,Description) Values(29 	 ,'Production Plan Start')
Insert Into Message_Types(Message_Id,Description) Values(30 	 ,'Production Stat')
Insert Into Message_Types(Message_Id,Description) Values(31 	 ,'Historian Read')
Insert Into Message_Types(Message_Id,Description) Values(32 	 ,'Non Productive')
Insert Into Message_Types(Message_Id,Description) Values(33 	 ,'Crew Schedule')
Insert Into Message_Types(Message_Id,Description) Values(34 	 ,'Event And Detail')
Insert Into Message_Types(Message_Id,Description) Values(35 	 ,'SimulateCalculations')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 0 	 ,'UserId','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 1 	 ,'ServiceId','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 2 	 ,'Name','MSOPropString')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 3 	 ,'Value','MSOPropString')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 4 	 ,'TransType','MSOPropUChar')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 5 	 ,'VarId','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 6 	 ,'TestId','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 7 	 ,'PUId','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 8 	 ,'SourcePUId','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 9 	 ,'ShouldArchive','MSOPropUChar')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 10 	 ,'Canceled','MSOPropUChar')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 11 	 ,'ResultOn','MSOPropDate')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 12 	 ,'EntryOn','MSOPropDate')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 13 	 ,'EventId','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 14 	 ,'AppProdId','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 15 	 ,'SrcEventId','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 16 	 ,'EventStatus','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 17 	 ,'Confirmed','MSOPropUChar')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 18 	 ,'TimeStamp','MSOPropDate')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 19 	 ,'EventNum','MSOPropString')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 20 	 ,'StartTime','MSOPropDate')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 21 	 ,'EndTime','MSOPropDate')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 22 	 ,'StartId','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 23 	 ,'ProdId','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 24 	 ,'StatusId','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 25 	 ,'FaultId','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 26 	 ,'TimedEventId','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 27 	 ,'ProdRate','MSOPropDouble')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 28 	 ,'Duration','MSOPropDouble')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 29 	 ,'Reason1Id','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 30 	 ,'Reason2Id','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 31 	 ,'Reason3Id','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 32 	 ,'Reason4Id','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 33 	 ,'TypeId','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 34 	 ,'MeasId','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 35 	 ,'Amount','MSOPropDouble')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 36 	 ,'Marker1','MSOPropDouble')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 37 	 ,'Marker2','MSOPropDouble')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 38 	 ,'SheetId','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 39 	 ,'WasteEventId','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 40 	 ,'BCType','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 41 	 ,'BIType','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 42 	 ,'TestNum','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 43 	 ,'TestSet','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 44 	 ,'AppStatus','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 45 	 ,'SubItem','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 46 	 ,'SubKey','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 47 	 ,'SubAll','MSOPropUChar')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 48 	 ,'ClearAll','MSOPropUChar')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 49 	 ,'ResetAll','MSOPropUChar')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 50 	 ,'JumpAhead','MSOPropUChar')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 51 	 ,'Reason','MSOPropString')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 52 	 ,'Services','MSOPropBuffer')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 53 	 ,'Start','MSOPropUChar')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 54 	 ,'All','MSOPropUChar')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 55 	 ,'ClientId','MSOPropString')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 56 	 ,'Connecting','MSOPropUChar')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 57 	 ,'ClientAccepted','MSOPropUChar')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 58 	 ,'BufferingOk','MSOPropUChar')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 59 	 ,'ShutdownReason','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 60 	 ,'ResultSet','MSOPropBuffer')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 61 	 ,'ResultSetKey','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 62 	 ,'Subscriptions','MSOPropBuffer')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 63 	 ,'CommentId','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 64 	 ,'Description','MSOPropString')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 65 	 ,'TransNum','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 66 	 ,'AlarmId','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 67 	 ,'ATDId','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 68 	 ,'AlarmDuration','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 69 	 ,'Ack','MSOPropUChar')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 70 	 ,'AckOn','MSOPropDate')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 71 	 ,'AckBy','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 72 	 ,'StartValue','MSOPropString')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 73 	 ,'EndValue','MSOPropString')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 74 	 ,'MinValue','MSOPropString')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 75 	 ,'Action1','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 76 	 ,'Action2','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 77 	 ,'Action3','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 78 	 ,'Action4','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 79 	 ,'ActionCommentId','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 80 	 ,'ResearchStatusId','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 81 	 ,'ResearchOpenDate','MSOPropDate')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 82 	 ,'ResearchCloseDate','MSOPropDate')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 83 	 ,'ResearchCommentId','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 84 	 ,'UDEventSubTypeDesc','MSOPropString')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 85 	 ,'UDEDuration','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 86 	 ,'ArrayId','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 87 	 ,'EventSubTypeId','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 88 	 ,'TestingStatus','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 89 	 ,'TargetProdRate','MSOPropDouble')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 90 	 ,'DimensionX1','MSOPropDouble')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 91 	 ,'DimensionY1','MSOPropDouble')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 92 	 ,'DimensionZ1','MSOPropDouble')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 93 	 ,'DimensionX2','MSOPropDouble')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 94 	 ,'DimensionY2','MSOPropDouble')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 95 	 ,'DimensionZ2','MSOPropDouble')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 96 	 ,'DimensionA1','MSOPropDouble')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 97 	 ,'DimensionA2','MSOPropDouble')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 98 	 ,'ComponentId','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 99 	 ,'AltEventNum','MSOPropString')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 100 	 ,'EventType','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 101 	 ,'OrientationX1','MSOPropDouble')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 102 	 ,'OrientationY1','MSOPropDouble')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 103 	 ,'OrientationZ1','MSOPropDouble')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 104 	 ,'OrderId','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 105 	 ,'OrderLineId','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 106 	 ,'ShipmentId','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 107 	 ,'PPId','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 108 	 ,'PPSetupDetailId','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 109 	 ,'ResultSetNum','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 110 	 ,'ContainerId','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 111 	 ,'ContainerStatusId','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 112 	 ,'PEIPId','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 113 	 ,'PEIId','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 114 	 ,'Unloaded','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 115 	 ,'ResearchUserId','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 116 	 ,'MaxValue','MSOPropString')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 117 	 ,'InAlarm','MSOPropUChar')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 118 	 ,'AlarmTypeId','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 119 	 ,'AlarmKeyId','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 120 	 ,'AlarmControlFlag','MSOPropUChar')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 121 	 ,'AlarmTempVarCmtId','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 122 	 ,'PermClient','MSOPropUChar')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 123 	 ,'UDECommentId','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 124 	 ,'AlarmVarCommentId','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 125 	 ,'APId','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 126 	 ,'ATId','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 127 	 ,'ChildUnitId','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 128 	 ,'EmptyQueueMask','MSOPropUChar')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 129 	 ,'AlarmCutoff','MSOPropUChar')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 130 	 ,'OPCRequest','MSOPropBuffer')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 131 	 ,'ResponseInfo','MSOPropBuffer')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 132 	 ,'GenericId','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 133 	 ,'ATSRDId','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 134 	 ,'ModifiedStartTime','MSOPropDate')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 135 	 ,'ModifiedEndTime','MSOPropDate')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 136 	 ,'ReloadMode','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 137 	 ,'DefectDetailId','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 138 	 ,'DefectTypeId','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 139 	 ,'StartCoordinateX','MSOPropDouble')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 140 	 ,'StartCoordinateY','MSOPropDouble')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 141 	 ,'StartCoordinateZ','MSOPropDouble')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 142 	 ,'StartCoordinateA','MSOPropDouble')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 143 	 ,'NotUsed1','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 144 	 ,'NotUsed2','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 145 	 ,'Severity','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 146 	 ,'Repeat','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 147 	 ,'Conformance','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 148 	 ,'TestPctComplete','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 149 	 ,'UserName','MSOPropString')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 150 	 ,'Password','MSOPropBuffer')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 151 	 ,'ValidUserCode','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 152 	 ,'Platform','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 153 	 ,'DLLName','MSOPropString')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 154 	 ,'BTimeStamp','MSOPropBuffer')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 155 	 ,'BStartTime','MSOPropBuffer')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 156 	 ,'BEndTime','MSOPropBuffer')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 157 	 ,'TagId','MSOPropString')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 158 	 ,'TagMask','MSOPropString')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 159 	 ,'TagList','MSOPropRecordSet')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 160 	 ,'DblValue','MSOPropDouble')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 161 	 ,'ValueStatus','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 162 	 ,'WriteWithWait','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 163 	 ,'PointClass','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 164 	 ,'SampMode','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 165 	 ,'Direction','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 166 	 ,'CalcMode','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 167 	 ,'SampInterval','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 168 	 ,'NumValues','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 169 	 ,'DataList','MSOPropBuffer')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 170 	 ,'OptionInfo','MSOPropRecordSet')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 171 	 ,'LogMessage','MSOPropString')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 172 	 ,'ApprovedUserId','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 173 	 ,'SecondUserId','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 174 	 ,'RemoteNode','MSOPropString')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 175 	 ,'SignOffId','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 176 	 ,'PEPUSId','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 177 	 ,'PathId','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 178 	 ,'PPSetupId','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 179 	 ,'PPStatusId','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 180 	 ,'PPStartId','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 181 	 ,'SourcePPId','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 182 	 ,'ParentPPId','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 183 	 ,'PPTypeId','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 184 	 ,'ForecastStartTime','MSOPropDate')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 185 	 ,'ForecastEndTime','MSOPropDate')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 186 	 ,'ForecastQuantity','MSOPropDouble')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 187 	 ,'ImpliedSequence','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 188 	 ,'PatternRepetitions','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 189 	 ,'PatternCode','MSOPropString')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 190 	 ,'BaseGeneral1','MSOPropDouble')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 191 	 ,'BaseGeneral2','MSOPropDouble')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 192 	 ,'BaseGeneral3','MSOPropDouble')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 193 	 ,'BaseGeneral4','MSOPropDouble')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 194 	 ,'Shrinkage','MSOPropDouble')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 195 	 ,'BlockNumber','MSOPropString')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 196 	 ,'OrderNum','MSOPropString')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 197 	 ,'AdjustedQuantity','MSOPropDouble')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 198 	 ,'ControlType','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 199 	 ,'StatsType','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 200 	 ,'ActualStartTime','MSOPropDate')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 201 	 ,'ActualEndTime','MSOPropDate')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 202 	 ,'ActualRunningTime','MSOPropDouble')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 203 	 ,'ActualDownTime','MSOPropDouble')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 204 	 ,'ActualGoodQuantity','MSOPropDouble')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 205 	 ,'ActualBadQuantity','MSOPropDouble')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 206 	 ,'ActualGoodItems','MSOPropDouble')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 207 	 ,'ActualBadItems','MSOPropDouble')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 208 	 ,'PredictedTotalDuration','MSOPropDouble')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 209 	 ,'PredictedRemainingDuration','MSOPropDouble')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 210 	 ,'PredictedRemainingQuantity','MSOPropDouble')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 211 	 ,'AlarmCount','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 212 	 ,'LateItems','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 213 	 ,'AlarmSubTypeId','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 214 	 ,'Repetitions','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 215 	 ,'LicEncCode','MSOPropBuffer')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 216 	 ,'LicModuleId','MSOPropBuffer')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 217 	 ,'LicModelId','MSOPropBuffer')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 218 	 ,'LicClientId','MSOPropBuffer')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 219 	 ,'LicResultValue','MSOPropBuffer')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 220 	 ,'LicClientNode','MSOPropBuffer')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 221 	 ,'LicAppDescription','MSOPropBuffer')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 222 	 ,'LicLicenseData','MSOPropBuffer')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 223 	 ,'ParentPPSetupId','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 224 	 ,'Misc1','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 225 	 ,'Misc2','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 226 	 ,'Misc3','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 227 	 ,'Misc4','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 228 	 ,'ExtendedInfo','MSOPropString')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 229 	 ,'PPComponentId','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 230 	 ,'RsnTreeDataId','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 231 	 ,'SampType','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 232 	 ,'LagTime','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 233 	 ,'ATVRDId','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 234 	 ,'General1','MSOPropString')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 235 	 ,'General2','MSOPropString')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 236 	 ,'General3','MSOPropString')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 237 	 ,'General4','MSOPropString')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 238 	 ,'General5','MSOPropString')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 239 	 ,'BOMFormulationId','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 240 	 ,'ECId','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 241 	 ,'ESigId','MSOPropInt64')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 242 	 ,'EmbeddedMsgs','MSOPropRecordSet')
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 243 	 ,'UserDefProperties',NULL)
Insert Into Message_Properties(MsgPropertyId,MsgPropertyDesc,MsgPropertyDataType) Values( 	 244 	 ,'IsLocked','MSOPropUChar')
Insert Into ResultSetTypes(RSTId,RSTDesc,Message_Id,PreColumnNum,PostColumnNum,PreRouteId,PostRouteId,KeyColumnNum) Values(1,'Production Event',4,null,12,6,7,5)
Insert Into ResultSetTypes(RSTId,RSTDesc,Message_Id,PreColumnNum,PostColumnNum,PreRouteId,PostRouteId,KeyColumnNum) Values(2,'Variable Result',3,null,8,13,14,1)
Insert Into ResultSetTypes(RSTId,RSTDesc,Message_Id,PreColumnNum,PostColumnNum,PreRouteId,PostRouteId,KeyColumnNum) Values(3,'Product Change',5,null,5,4,5,2)
Insert Into ResultSetTypes(RSTId,RSTDesc,Message_Id,PreColumnNum,PostColumnNum,PreRouteId,PostRouteId,KeyColumnNum) Values(4,'Topic',0,null,null,25,25,2)
Insert Into ResultSetTypes(RSTId,RSTDesc,Message_Id,PreColumnNum,PostColumnNum,PreRouteId,PostRouteId,KeyColumnNum) Values(5,'Delay',6,null,15,9,10,1)
Insert Into ResultSetTypes(RSTId,RSTDesc,Message_Id,PreColumnNum,PostColumnNum,PreRouteId,PostRouteId,KeyColumnNum) Values(6,'Alarm Event',17,1,null,30,31,32)
Insert Into ResultSetTypes(RSTId,RSTDesc,Message_Id,PreColumnNum,PostColumnNum,PreRouteId,PostRouteId,KeyColumnNum) Values(7,'Sheet Column',8,null,5,1,2,1)
Insert Into ResultSetTypes(RSTId,RSTDesc,Message_Id,PreColumnNum,PostColumnNum,PreRouteId,PostRouteId,KeyColumnNum) Values(8,'User Defined Event',18,1,null,28,29,4)
Insert Into ResultSetTypes(RSTId,RSTDesc,Message_Id,PreColumnNum,PostColumnNum,PreRouteId,PostRouteId,KeyColumnNum) Values(9,'Waste',7,1,null,11,12,6)
Insert Into ResultSetTypes(RSTId,RSTDesc,Message_Id,PreColumnNum,PostColumnNum,PreRouteId,PostRouteId,KeyColumnNum) Values(10,'Event Detail',14,1,null,32,33,6)
Insert Into ResultSetTypes(RSTId,RSTDesc,Message_Id,PreColumnNum,PostColumnNum,PreRouteId,PostRouteId,KeyColumnNum) Values(11,'Event Component',19,1,null,34,35,23)
Insert Into ResultSetTypes(RSTId,RSTDesc,Message_Id,PreColumnNum,PostColumnNum,PreRouteId,PostRouteId,KeyColumnNum) Values(12,'Input Event',21,1,null,36,37,8)
Insert Into ResultSetTypes(RSTId,RSTDesc,Message_Id,PreColumnNum,PostColumnNum,PreRouteId,PostRouteId,KeyColumnNum) Values(13,'Defect Detail',22,1,null,40,41,21)
Insert Into ResultSetTypes(RSTId,RSTDesc,Message_Id,PreColumnNum,PostColumnNum,PreRouteId,PostRouteId,KeyColumnNum) Values(14,'Historian Write',25,null,null,42,42,null)
Insert Into ResultSetTypes(RSTId,RSTDesc,Message_Id,PreColumnNum,PostColumnNum,PreRouteId,PostRouteId,KeyColumnNum) Values(15,'Production Plan',28,1,null,43,44,4)
Insert Into ResultSetTypes(RSTId,RSTDesc,Message_Id,PreColumnNum,PostColumnNum,PreRouteId,PostRouteId,KeyColumnNum) Values(16,'Production Setup',27,1,null,47,48,4)
Insert Into ResultSetTypes(RSTId,RSTDesc,Message_Id,PreColumnNum,PostColumnNum,PreRouteId,PostRouteId,KeyColumnNum) Values(17,'Production Plan Start',29,1,null,45,46,4)
Insert Into ResultSetTypes(RSTId,RSTDesc,Message_Id,PreColumnNum,PostColumnNum,PreRouteId,PostRouteId,KeyColumnNum) Values(18,'Prd Exec Path Unit Start',26,1,null,51,52,4)
Insert Into ResultSetTypes(RSTId,RSTDesc,Message_Id,PreColumnNum,PostColumnNum,PreRouteId,PostRouteId,KeyColumnNum) Values(19,'Production Stat',30,1,null,49,50,4)
Insert Into ResultSetTypes(RSTId,RSTDesc,Message_Id,PreColumnNum,PostColumnNum,PreRouteId,PostRouteId,KeyColumnNum) Values(20,'Historian Read',31,null,null,53,53,null)
Insert Into ResultSetTypes(RSTId,RSTDesc,Message_Id,PreColumnNum,PostColumnNum,PreRouteId,PostRouteId,KeyColumnNum) Values(21,'Non Productive Event',32,1,null,54,55,4)
Insert Into ResultSetTypes(RSTId,RSTDesc,Message_Id,PreColumnNum,PostColumnNum,PreRouteId,PostRouteId,KeyColumnNum) Values(50,'Build File',null,null,null,null,null,null)
Insert Into ResultSetTypes(RSTId,RSTDesc,Message_Id,PreColumnNum,PostColumnNum,PreRouteId,PostRouteId,KeyColumnNum) Values(51,'SP Return Parameters',null,null,null,null,null,null)
-- Production Event
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(1,0,'RSTId',null,null,null)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(1,1,'NotUsed',null,null,null)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(1,2,'TransType','1',null,4)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(1,3,'EventId',null,null,13)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(1,4,'EventNum',null,null,19)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(1,5,'PUId',null,null,7)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(1,6,'TimeStamp',null,null,18)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(1,7,'AppProdId',null,null,14)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(1,8,'SrcEventId',null,null,15)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(1,9,'EventStatus',null,null,16)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(1,10,'Confirmed','1',null,17)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(1,11,'UserId',null,null,0)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(1,12,'PostDB',null,null,null)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(1,13,'Conformance','-1',null,147)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(1,14,'TestPctComplete','-1',null,148)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(1,15,'StartTime',null,null,20)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(1,16,'TransNum','0',null,65)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(1,17,'TestingStatus',null,null,88)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(1,18,'CommentId',null,null,63)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(1,19,'EventSubTypeId',null,null,87)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(1,20,'EntryOn',null,null,12)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(1,21,'ApprovedUserId',null,null,172)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(1,22,'Obsolete',null,null,173)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(1,23,'ApprovedReasonId',null,'Reason1Id',29)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(1,24,'UserReasonId',null,'Reason2Id',30)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(1,25,'SignOffId',null,null,175)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(1,26,'ExtendedInfo',null,null,228)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(1,27,'ESigId',null,null,241)
-- Variable Result Event
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(2,0,'RSTId',null,null,null)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(2,1,'VarId',null,null,5)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(2,2,'PUId',null,null,7)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(2,3,'UserId',null,null,0)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(2,4,'Canceled',null,null,10)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(2,5,'Result',null,'Value',3)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(2,6,'ResultOn',null,null,11)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(2,7,'TransType','1',null,4)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(2,8,'PostDB',null,null,null)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(2,9,'SecondUserId',null,null,173)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(2,10,'TransNum','0',null,65)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(2,11,'EventId',null,null,13)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(2,12,'ArrayId',null,null,86)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(2,13,'CommentId',null,null,63)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(2,14,'ESigId',null,null,241)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(2,15,'EntryOn',null,null,12)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(2,16,'TestId',null,null,6)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(2,17,'ShouldArchive','1',null,9)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(2,18,'HasHistory',null,'Misc1',224)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(2,19,'IsLocked','0',null,244)
-- Product Change Event
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(3,0,'RSTId',null,null,null)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(3,1,'StartId',null,null,22)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(3,2,'PUId',null,null,7)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(3,3,'ProdId',null,null,23)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(3,4,'StartTime',null,null,20)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(3,5,'PostDB',null,null,null)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(3,6,'UserId',null,null,0)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(3,7,'SecondUserId',null,null,173)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(3,8,'TransType','1',null,4)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(3,9,'ESigId',null,null,241)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(3,10,'TransNum','0',null,65)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(3,11,'Confirmed','1',null,17)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(3,12,'CommentId','0',null,63)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(3,13,'EventSubTypeId','0',null,87)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(3,14,'EndTime',null,null,21)
-- Topic
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(4,0,'RSTId',null,null,null)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(4,1,'TopicId',null,null,null)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(4,2,'TopicKey',null,null,null)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(4,3,'TopicValue',null,null,null)
-- Downtime Event
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(5,0,'RSTId',null,null,null)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(5,1,'PUId',null,null,7)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(5,2,'SourcePUId',null,null,8)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(5,3,'StatusId',null,null,24)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(5,4,'FaultId',null,null,25)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(5,5,'Reason1Id',null,null,29)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(5,6,'Reason2Id',null,null,30)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(5,7,'Reason3Id',null,null,31)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(5,8,'Reason4Id',null,null,32)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(5,9,'ProdRate','0.0',null,27)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(5,10,'NotUsed',null,null,null)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(5,11,'TransType','1',null,4)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(5,12,'StartTime',null,null,20)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(5,13,'EndTime',null,null,21)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(5,14,'TimedEventId',null,null,26)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(5,15,'PostDB',null,null,null)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(5,16,'TransNum','0',null,65)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(5,17,'Action1',null,null,75)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(5,18,'Action2',null,null,76)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(5,19,'Action3',null,null,77)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(5,20,'Action4',null,null,78)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(5,21,'ActionCommentId',null,null,79)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(5,22,'ResearchCommentId',null,null,83)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(5,23,'ResearchStatusId',null,null,80)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(5,24,'ResearchOpenDate',null,null,81)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(5,25,'ResearchCloseDate',null,null,82)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(5,26,'CommentId',null,null,63)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(5,27,'Obsolete','0.0',null,89)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(5,28,'Obsolete','0.0',null,90)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(5,29,'Obsolete','0.0',null,93)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(5,30,'Obsolete','0.0',null,91)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(5,31,'Obsolete','0.0',null,94)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(5,32,'Obsolete','0.0',null,92)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(5,33,'Obsolete','0.0',null,95)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(5,34,'ResearchUserId',null,null,115)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(5,35,'RsnTreeDataId',null,null,230)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(5,36,'ESigId',null,null,241)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(5,37,'UserId',null,null,0)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(5,38,'Duration','0',null,28)
-- Alarm Event
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(6,0,'RSTId',null,null,null)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(6,1,'PreDB',null,null,null)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(6,2,'TransNum',null,null,65)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(6,3,'AlarmId',null,null,66)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(6,4,'ATDId',null,null,67)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(6,5,'StartTime',null,null,20)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(6,6,'EndTime',null,null,21)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(6,7,'AlarmDuration',null,null,68)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(6,8,'Ack',null,null,69)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(6,9,'AckOnTime',null,'AckOn',70)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(6,10,'AckBy',null,null,71)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(6,11,'StartValue',null,null,72)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(6,12,'EndValue',null,null,73)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(6,13,'MinValue',null,null,74)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(6,14,'MaxValue',null,null,116)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(6,15,'Cause1',null,'Reason1Id',29)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(6,16,'Cause2',null,'Reason2Id',30)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(6,17,'Cause3',null,'Reason3Id',31)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(6,18,'Cause4',null,'Reason4Id',32)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(6,19,'CauseCommentId',null,'CommentId',63)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(6,20,'Action1',null,null,75)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(6,21,'Action2',null,null,76)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(6,22,'Action3',null,null,77)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(6,23,'Action4',null,null,78)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(6,24,'ActionCommentId',null,null,79)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(6,25,'ResearchUserId',null,null,115)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(6,26,'ResearchStatusId',null,null,80)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(6,27,'ResearchOpenDate',null,null,81)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(6,28,'ResearchCloseDate',null,null,82)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(6,29,'ResearchCommentId',null,null,83)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(6,30,'SourcePUId',null,null,8)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(6,31,'AlarmTypeId',null,null,118)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(6,32,'AlarmKeyId',null,null,119)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(6,33,'Description',null,null,64)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(6,34,'TransType','0',null,4)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(6,35,'CommentId',null,'AlarmTempVarCmtId',121)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(6,36,'APId',null,null,125)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(6,37,'ATId',null,null,126)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(6,38,'VarCommentId',null,'AlarmVarCommentId',124)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(6,39,'AlarmCutoff',null,null,129)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(6,40,'ESigId',null,null,241)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(6,41,'PathId',null,null,177)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(6,42,'UserId',null,null,0)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(6,43,'ATSRDId',null,null,133)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(6,44,'AlarmSubTypeId',null,null,213)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(6,45,'ATVRDId',null,null,233)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(6,46,'CurrentValue',null,'Value',3)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(6,47,'InAlarm','0',null,117)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(6,48,'AlarmControlFlag','0',null,120)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(6,49,'CurrentTime',null,'ResultOn',11)
-- Sheet Column
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(7,0,'RSTId',null,null,null)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(7,1,'SheetId',null,null,38)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(7,2,'UserId',null,null,0)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(7,3,'TransType','1',null,4)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(7,4,'TimeStamp',null,null,18)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(7,5,'PostDB',null,null,null)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(7,6,'ApprovedUserId',null,null,172)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(7,7,'ApprovedReasonId',null,'Reason1Id',29)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(7,8,'UserReasonId',null,'Reason2Id',30)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(7,9,'SignOffId',null,null,175)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(7,10,'ESigId',null,null,241)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(7,11,'TransNum','0',null,65)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(7,12,'CommentId',null,null,63)
-- User Defined Event
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(8,0,'RSTId',null,null,null)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(8,1,'PreDB',null,null,null)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(8,2,'UDEId',null,'EventId',13)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(8,3,'UDENum',null,'EventNum',19)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(8,4,'PUId',null,null,7)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(8,5,'EventSubtypeId',null,null,87)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(8,6,'StartTime',null,null,20)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(8,7,'EndTime',null,null,21)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(8,8,'UDEDuration',null,null,85)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(8,9,'Ack',null,null,69)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(8,10,'AckOn',null,null,70)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(8,11,'AckBy',null,null,71)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(8,12,'Cause1',null,'Reason1Id',29)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(8,13,'Cause2',null,'Reason2Id',30)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(8,14,'Cause3',null,'Reason3Id',31)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(8,15,'Cause4',null,'Reason4Id',32)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(8,16,'CommentId',null,null,63)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(8,17,'Action1',null,null,75)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(8,18,'Action2',null,null,76)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(8,19,'Action3',null,null,77)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(8,20,'Action4',null,null,78)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(8,21,'ActionCommentId',null,null,79)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(8,22,'ResearchUserId',null,null,115)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(8,23,'ResearchStatusId',null,null,80)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(8,24,'ResearchOpenDate',null,null,81)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(8,25,'ResearchCloseDate',null,null,82)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(8,26,'ResearchCommentId',null,null,83)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(8,27,'UDECommentId',null,null,123)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(8,28,'TransType','0',null,4)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(8,29,'EventSubTypeDesc',null,'UDEventSubTypeDesc',84)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(8,30,'TransNum','0',null,65)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(8,31,'UserId',null,null,0)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(8,32,'ESigId',null,null,241)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(8,33,'ProductionEventId',null,'Misc1',224)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(8,34,'ParentUDEId',null,'SrcEventId',15)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(8,35,'EventStatus',null,null,16)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(8,36,'TestingStatus',null,null,88)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(8,37,'TestPctComplete','-1',null,148)
-- Waste Event
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(9,0,'RSTId',null,null,null)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(9,1,'PreDB',null,null,null)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(9,2,'TransNum','0',null,65)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(9,3,'UserId',null,null,0)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(9,4,'TransType','0',null,4)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(9,5,'WasteEventId',null,null,39)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(9,6,'PUId',null,null,7)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(9,7,'SourcePUId',null,null,8)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(9,8,'TypeId',null,null,33)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(9,9,'MeasId',null,null,34)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(9,10,'Reason1',null,'Reason1Id',29)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(9,11,'Reason2',null,'Reason2Id',30)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(9,12,'Reason3',null,'Reason3Id',31)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(9,13,'Reason4',null,'Reason4Id',32)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(9,14,'EventId',null,null,13)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(9,15,'Amount','0.0',null,35)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(9,16,'Obsolete','0.0',null,36)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(9,17,'Obsolete','0.0',null,37)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(9,18,'TimeStamp',null,null,18)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(9,19,'Action1',null,null,75)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(9,20,'Action2',null,null,76)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(9,21,'Action3',null,null,77)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(9,22,'Action4',null,null,78)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(9,23,'ActionCommentId',null,null,79)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(9,24,'ResearchCommentId',null,null,83)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(9,25,'ResearchStatusId',null,null,80)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(9,26,'ResearchOpenDate',null,null,81)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(9,27,'ResearchCloseDate',null,null,82)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(9,28,'CommentId',null,null,63)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(9,29,'Obsolete','0.0',null,89)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(9,30,'ResearchUserId',null,null,115)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(9,31,'FaultId',null,null,25)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(9,32,'RsnTreeDataId',null,null,230)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(9,33,'DimensionX',null,'DimensionX1',90)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(9,34,'DimensionY',null,'DimensionY1',91)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(9,35,'DimensionZ',null,'DimensionZ1',92)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(9,36,'DimensionA',null,'DimensionA1',96)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(9,37,'StartCoordinateX',null,null,139)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(9,38,'StartCoordinateY',null,null,140)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(9,39,'StartCoordinateZ',null,null,141)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(9,40,'StartCoordinateA',null,null,142)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(9,41,'General1',null,null,234)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(9,42,'General2',null,null,235)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(9,43,'General3',null,null,236)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(9,44,'General4',null,null,237)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(9,45,'General5',null,null,238)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(9,46,'OrderNum',null,null,196)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(9,47,'ECID',null,null,240)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(9,48,'ESigId',null,null,241)
-- Event Detail
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(10,0,'RSTId',null,null,null)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(10,1,'PreDB',null,null,null)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(10,2,'UserId',null,null,0)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(10,3,'TransType','1',null,4)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(10,4,'TransNum','0',null,65)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(10,5,'EventId',null,null,13)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(10,6,'PUId',null,null,7)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(10,7,'Obsolete',null,null,null)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(10,8,'AltEventNum',null,null,99)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(10,9,'CommentId',null,null,63)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(10,10,'Obsolete',null,null,null)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(10,11,'Obsolete',null,null,null)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(10,12,'Obsolete',null,null,null)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(10,13,'Obsolete',null,null,null)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(10,14,'TimeStamp',null,null,18)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(10,15,'EntryOn',null,null,12)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(10,16,'PPSetupDetailId',null,null,108)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(10,17,'ShipmentId',null,null,106)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(10,18,'OrderId',null,null,104)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(10,19,'OrderLineId',null,null,105)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(10,20,'PPId',null,null,107)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(10,21,'InitialDimensionX',null,'DimensionX1',90)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(10,22,'InitialDimensionY',null,'DimensionY1',91)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(10,23,'InitialDimensionZ',null,'DimensionZ1',92)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(10,24,'InitialDimensionA',null,'DimensionA1',96)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(10,25,'FinalDimensionX',null,'DimensionX2',93)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(10,26,'FinalDimensionY',null,'DimensionY2',94)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(10,27,'FinalDimensionZ',null,'DimensionZ2',95)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(10,28,'FinalDimensionA',null,'DimensionA2',97)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(10,29,'OrientationX',null,'OrientationX1',101)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(10,30,'OrientationY',null,'OrientationY1',102)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(10,31,'OrientationZ',null,'OrientationZ1',103)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(10,32,'ESigId',null,null,241)
-- Event Component
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(11,0,'RSTId',null,null,null)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(11,1,'PreDB',null,null,null)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(11,2,'UserId',null,null,0)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(11,3,'TransType','1',null,4)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(11,4,'TransNum','0',null,65)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(11,5,'ComponentId',null,null,98)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(11,6,'EventId',null,null,13)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(11,7,'SrcEventId',null,null,15)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(11,8,'DimensionX',null,'DimensionX1',90)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(11,9,'DimensionY',null,'DimensionY1',91)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(11,10,'DimensionZ',null,'DimensionZ1',92)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(11,11,'DimensionA',null,'DimensionA1',96)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(11,12,'StartCoordinateX',null,null,139)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(11,13,'StartCoordinateY',null,null,140)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(11,14,'StartCoordinateZ',null,null,141)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(11,15,'StartCoordinateA',null,null,142)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(11,16,'StartTime',null,null,20)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(11,17,'Timestamp',null,null,18)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(11,18,'PPComponentId',null,null,229)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(11,19,'EntryOn',null,null,12)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(11,20,'ExtendedInfo',null,null,228)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(11,21,'PEIId',null,null,113)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(11,22,'ReportAsConsumption','-1','Misc1',224)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(11,23,'ChildUnitId',null,null,127)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(11,24,'ESigId',null,null,241)
-- Input Event
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(12,0,'RSTId',null,null,null)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(12,1,'PreDB',null,null,null)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(12,2,'UserId',null,null,0)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(12,3,'TransType','1',null,4)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(12,4,'TransNum','0',null,65)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(12,5,'TimeStamp',null,null,18)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(12,6,'EntryOn',null,null,12)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(12,7,'CommentId',null,null,63)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(12,8,'PEIId',null,null,113)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(12,9,'PEIPId',null,null,112)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(12,10,'EventId',null,null,13)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(12,11,'DimensionX',null,'DimensionX1',90)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(12,12,'DimensionY',null,'DimensionY1',91)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(12,13,'DimensionZ',null,'DimensionZ1',92)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(12,14,'DimensionA',null,'DimensionA1',96)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(12,15,'Unloaded',null,null,114)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(12,16,'ESigId',null,null,241)
-- Defect Detail
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(13,0,'RSTId',null,null,null)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(13,1,'PreDB',null,null,null)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(13,2,'TransType','1',null,4)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(13,3,'TransNum','0',null,65)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(13,4,'DefectDetailId',null,null,137)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(13,5,'DefectTypeId',null,null,138)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(13,6,'Cause1',null,'Reason1Id',29)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(13,7,'Cause2',null,'Reason2Id',30)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(13,8,'Cause3',null,'Reason3Id',31)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(13,9,'Cause4',null,'Reason4Id',32)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(13,10,'CauseCommentId',null,'CommentId',63)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(13,11,'Action1',null,null,75)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(13,12,'Action2',null,null,76)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(13,13,'Action3',null,null,77)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(13,14,'Action4',null,null,78)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(13,15,'ActionCommentId',null,null,79)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(13,16,'ResearchStatusId',null,null,80)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(13,17,'ResearchCommentId',null,null,83)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(13,18,'ResearchUserId',null,null,115)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(13,19,'EventId',null,null,13)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(13,20,'SourcePUId',null,null,8)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(13,21,'PUId',null,null,7)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(13,22,'EventSubtypeId',null,null,87)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(13,23,'UserId',null,null,0)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(13,24,'Severity',null,null,145)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(13,25,'Repeat',null,null,146)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(13,26,'DimensionX',null,'DimensionX1',90)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(13,27,'DimensionY',null,'DimensionY1',91)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(13,28,'DimensionZ',null,'DimensionZ1',92)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(13,29,'DimensionA',null,'DimensionA1',96)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(13,30,'Amount',null,null,35)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(13,31,'StartCoordinateX',null,null,139)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(13,32,'StartCoordinateY',null,null,140)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(13,33,'StartCoordinateZ',null,null,141)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(13,34,'StartCoordinateA',null,null,142)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(13,35,'ResearchOpenDate',null,null,81)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(13,36,'ResearchCloseDate',null,null,82)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(13,37,'StartTime',null,null,20)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(13,38,'EndTime',null,null,21)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(13,39,'EntryOn',null,null,12)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(13,40,'ESigId',null,null,241)
-- Historian Write
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(14,0,'RSTId',null,null,null)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(14,1,'NodeAlias',null,'RemoteNode',174)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(14,2,'Tag',null,'Name',2)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(14,3,'Value',null,null,3)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(14,4,'TimeStamp',null,'ResultOn',11)
-- Production Plan
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(15,0,'RSTId',null,null,null)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(15,1,'PreDB',null,null,null)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(15,2,'TransType','1',null,4)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(15,3,'TransNum','0',null,65)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(15,4,'PathId',null,null,177)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(15,5,'PPId',null,null,107)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(15,6,'CommentId',null,null,63)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(15,7,'ProdId',null,null,23)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(15,8,'ImpliedSequence',null,null,187)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(15,9,'PPStatusId',null,null,179)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(15,10,'PPTypeId',null,null,183)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(15,11,'SourcePPId',null,null,181)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(15,12,'UserId',null,null,0)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(15,13,'ParentPPId',null,null,182)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(15,14,'ControlType',null,null,198)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(15,15,'ForecastStartTime',null,null,184)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(15,16,'ForecastEndTime',null,null,185)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(15,17,'EntryOn',null,null,12)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(15,18,'ForecastQuantity',null,null,186)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(15,19,'ProductionRate',null,'ProdRate',27)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(15,20,'AdjustedQuantity',null,null,197)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(15,21,'BlockNumber',null,null,195)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(15,22,'ProcessOrder',null,'OrderNum',196)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(15,23,'TransactionTime',null,'TimeStamp',18)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(15,24,'Misc1',null,null,224)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(15,25,'Misc2',null,null,225)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(15,26,'Misc3',null,null,226)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(15,27,'Misc4',null,null,227)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(15,28,'BOMFormulationId',null,null,239)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(15,29,'UserGen1',null,'General1',234)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(15,30,'UserGen2',null,'General2',235)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(15,31,'UserGen3',null,'General3',236)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(15,32,'ExtendedInfo',null,null,228)
-- Production Setup
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(16,0,'RSTId',null,null,null)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(16,1,'PreDB',null,null,null)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(16,2,'TransType','1',null,4)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(16,3,'TransNum','0',null,65)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(16,4,'PathId',null,null,177)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(16,5,'PPSetupId',null,null,178)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(16,6,'PPId',null,null,107)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(16,7,'ImpliedSequence',null,null,187)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(16,8,'PPStatusId',null,null,179)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(16,9,'PatternRepetitions',null,null,188)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(16,10,'CommentId',null,null,63)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(16,11,'ForecastQuantity',null,null,186)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(16,12,'BaseDimensionX',null,'DimensionX1',90)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(16,13,'BaseDimensionY',null,'DimensionY1',91)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(16,14,'BaseDimensionZ',null,'DimensionZ1',92)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(16,15,'BaseDimensionA',null,'DimensionA1',96)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(16,16,'BaseGeneral1',null,null,190)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(16,17,'BaseGeneral2',null,null,191)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(16,18,'BaseGeneral3',null,null,192)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(16,19,'BaseGeneral4',null,null,193)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(16,20,'Shrinkage',null,null,194)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(16,21,'PatternCode',null,null,189)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(16,22,'UserId',null,null,0)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(16,23,'EntryOn',null,null,12)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(16,24,'TransactionTime',null,'TimeStamp',18)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(16,25,'ParentPPSetupId',null,null,223)
-- Production Plan Start
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(17,0,'RSTId',null,null,null)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(17,1,'PreDB',null,null,null)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(17,2,'TransType','1',null,4)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(17,3,'TransNum','0',null,65)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(17,4,'PUId',null,null,7)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(17,5,'PPStartId',null,null,180)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(17,6,'StartTime',null,null,20)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(17,7,'EndTime',null,null,21)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(17,8,'PPId',null,null,107)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(17,9,'CommentId',null,null,63)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(17,10,'PPSetupId',null,null,178)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(17,11,'UserId',null,null,0)
-- Prd Exec Path Unit Start
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(18,0,'RSTId',null,null,null)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(18,1,'PreDB',null,null,null)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(18,2,'TransType','1',null,4)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(18,3,'TransNum','0',null,65)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(18,4,'PUId',null,null,7)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(18,5,'PEPUSId',null,null,176)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(18,6,'PathId',null,null,177)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(18,7,'CommentId',null,null,63)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(18,8,'StartTime',null,null,20)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(18,9,'EndTime',null,null,21)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(18,10,'UserId',null,null,0)
-- Production Stat
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(19,0,'RSTId',null,null,null)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(19,1,'PreDB',null,null,null)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(19,2,'TransType','1',null,4)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(19,3,'TransNum','0',null,65)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(19,4,'PathId',null,null,177)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(19,5,'StatsType',null,null,199)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(19,6,'Id',null,'EventId',13)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(19,7,'ActualStartTime',null,null,200)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(19,8,'ActualEndTime',null,null,201)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(19,9,'ActualGoodItems',null,null,206)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(19,10,'ActualBadItems',null,null,207)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(19,11,'ActualRunningTime',null,null,202)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(19,12,'ActualDownTime',null,null,203)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(19,13,'ActualGoodQuantity',null,null,204)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(19,14,'ActualBadQuantity',null,null,205)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(19,15,'PredictedTotalDuration',null,null,208)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(19,16,'PredictedRemainingDuration',null,null,209)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(19,17,'PredictedRemainingQuantity',null,null,210)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(19,18,'AlarmCount',null,null,211)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(19,19,'LateItems',null,null,212)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(19,20,'Repetitions',null,null,214)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(19,21,'PPId',0,null,107)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(19,22,'ParentPPId',0,null,182)
-- Historian Read
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(20,0,'RSTId',null,null,null)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(20,1,'StartTime',null,null,20)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(20,2,'EndTime',null,null,21)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(20,3,'Tag',null,'Name',2)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(20,4,'NodeAlias',null,'RemoteNode',174)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(20,5,'SampType',null,null,231)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(20,6,'VarID',null,null,5)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(20,7,'LagTime',null,null,232)
-- Non Productive Event
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(21,0,'RSTId',null,null,null)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(21,1,'PreDB',null,null,null)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(21,2,'TransactionType',null,'TransType',4)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(21,3,'TransNum','0',null,65)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(21,4,'PUId',null,null,7)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(21,5,'StartTime',null,null,20)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(21,6,'EndTime',null,null,21)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(21,7,'Reason1',null,'Reason1Id',29)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(21,8,'Reason2',null,'Reason2Id',30)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(21,9,'Reason3',null,'Reason3Id',31)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(21,10,'Reason4',null,'Reason4Id',32)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(21,11,'UserId',null,null,0)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(21,12,'CommentId',null,null,63)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(21,13,'RsnTreeDataId',null,null,230)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(21,14,'EntryOn',null,null,12)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(21,15,'NPDetId',null,'EventId',13)
-- Build File (Not Implemented in SDK)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(50,0,'RSTId',null,null,null)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(50,1,'File#',null,null,null)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(50,2,'Filename',null,null,null)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(50,3,'Field#',null,null,null)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(50,4,'FieldName',null,null,null)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(50,5,'Type',null,null,null)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(50,6,'Length',null,null,null)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(50,7,'Precision',null,null,null)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(50,8,'Value',null,null,3)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(50,9,'CariageReturn',null,null,null)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(50,10,'ConstructionPath',null,null,null)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(50,11,'FinalPath',null,null,null)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(50,12,'MoveMask (NO PATH)',null,null,null)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(50,13,'AddTimeStamp (0-No, 1-Short, 2-Full)',null,null,null)
-- SP Return Parameters (Not Implemented in SDK)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(51,0,'RSTId',null,null,null)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(51,1,'ParameterName',null,null,null)
Insert Into ResultSetConfig (RSTId,ColumnNum,UsedAsPropertyName,DefaultValue,ActualPropertyName,MsgPropertyId) Values(51,2,'ParameterValue',null,null,null)
insert into Performance_Objects(Object_Id, Name, Description) values (1, 'Messages', 'Service TCP Message Statistics')
insert into Performance_Objects(Object_Id, Name, Description) values (2, 'Caching', 	 'Data Caching Statistics')
insert into Performance_Objects(Object_Id, Name, Description) values (3, 'SP Times', 'Stored Proceedure Times Statistics')
insert into Performance_Objects(Object_Id, Name, Description) values (4, 'Calc Times', 'Calculation Times Statistics')
insert into Performance_Objects(Object_Id, Name, Description) values (5, 'FTP Times', 'FTP File Transfer Times Statistics')
insert into Performance_Objects(Object_Id, Name, Description) values (6, 'Starts/Stops', 'Service Start and Stop Statistics')
insert into Performance_Objects(Object_Id, Name, Description) values (7, 'Event Models', 'Event Model Times Statistics')
insert into Performance_Objects(Object_Id, Name, Description) values (8, 'Process Stats', 'Process Statistics (CPU, Memory, Etc)')
insert into Performance_Objects(Object_Id, Name, Description) values (9, 'Historian Stats', 'Historian API Call Statistics')
insert into Performance_Objects(Object_Id, Name, Description) values (10, 'ThreadPools Stats', 'Thread Pool Statistics')
-- Counters for Messages
insert into Performance_Counters (Counter_Id, Object_Id, Name, Description) values (0, 1, 'Bytes Received', 'Bytes recieved on socket.')
insert into Performance_Counters (Counter_Id, Object_Id, Name, Description) values (1, 1, 'Bytes Sent', 'Bytes sent on socket.')
insert into Performance_Counters (Counter_Id, Object_Id, Name, Description) values (2, 1, 'Msg Count (Input)', 'Number of messages on socket input queue.')
insert into Performance_Counters (Counter_Id, Object_Id, Name, Description) values (3, 1, 'Max Count (Input)', 'Max number of messages on socket output queue.')
insert into Performance_Counters (Counter_Id, Object_Id, Name, Description) values (4, 1, 'Msgs Sent', 'Number of messages sent on socket.')
insert into Performance_Counters (Counter_Id, Object_Id, Name, Description) values (5, 1, 'Msgs Received', 'Number of messages received on socket.')
-- Counters for Caching
insert into Performance_Counters (Counter_Id, Object_Id, Name, Description) values (0, 2, 'Hit Percentage', 'Hit rate percentage for the cache (0-100).')
insert into Performance_Counters (Counter_Id, Object_Id, Name, Description) values (1, 2, 'Hits', 'Number of hits in the cache.')
insert into Performance_Counters (Counter_Id, Object_Id, Name, Description) values (2, 2, 'Misses (Total)', 'Total Number of misses in the cache.')
insert into Performance_Counters (Counter_Id, Object_Id, Name, Description) values (3, 2, 'Cache Refills', 'Number of times cache was emptied and refilled.')
insert into Performance_Counters (Counter_Id, Object_Id, Name, Description) values (4, 2, 'Max Variables', 'Maximum number of variables that can be cached.')
insert into Performance_Counters (Counter_Id, Object_Id, Name, Description) values (5, 2, 'Values Per Var', 'Number of values per variables that can be cached.')
insert into Performance_Counters (Counter_Id, Object_Id, Name, Description) values (6, 2, 'Miss Too Old', 'Cache miss due to data older than the cache holds.')
insert into Performance_Counters (Counter_Id, Object_Id, Name, Description) values (7, 2, 'Miss Not Cached', 'Cache miss due to variable not being cached.')
insert into Performance_Counters (Counter_Id, Object_Id, Name, Description) values (8, 2, 'Vars Requested', 'Num variables that have been requested to be cached.')
insert into Performance_Counters (Counter_Id, Object_Id, Name, Description) values (9, 2, 'Vars Cached', 'Num variables that are being cached.')
insert into Performance_Counters (Counter_Id, Object_Id, Name, Description) values (10, 2, 'Pct Full (Vars)', 'How full is the variable list.')
insert into Performance_Counters (Counter_Id, Object_Id, Name, Description) values (11, 2, 'Pct Full (Data)', 'How full is the data portion of the cache.')
-- Counters for Stored Proceedures
insert into Performance_Counters (Counter_Id, Object_Id, Name, Description) values (0, 3, 'Average (ms)', 'Average time to run stored procedure.')
insert into Performance_Counters (Counter_Id, Object_Id, Name, Description) values (1, 3, 'Last (ms)', 'Last time to run stored procedure.')
insert into Performance_Counters (Counter_Id, Object_Id, Name, Description) values (2, 3, 'Minimum (ms)', 'Minimum time to run stored procedure.')
insert into Performance_Counters (Counter_Id, Object_Id, Name, Description) values (3, 3, 'Maximum (ms)', 'Maximum time to run stored procedure.')
insert into Performance_Counters (Counter_Id, Object_Id, Name, Description) values (4, 3, 'Num Executions', 'Number of times stored procedure was run.')
-- Counters for Calculation
insert into Performance_Counters (Counter_Id, Object_Id, Name, Description) values (0, 4, 'Average (ms)', 'Average time to run calculation.')
insert into Performance_Counters (Counter_Id, Object_Id, Name, Description) values (1, 4, 'Last (ms)', 'Last time to run calculation.')
insert into Performance_Counters (Counter_Id, Object_Id, Name, Description) values (2, 4, 'Minimum (ms)', 'Minimum time to run calculation.')
insert into Performance_Counters (Counter_Id, Object_Id, Name, Description) values (3, 4, 'Maximum (ms)', 'Maximum time to run calculation.')
insert into Performance_Counters (Counter_Id, Object_Id, Name, Description) values (4, 4, 'Num Executions', 'Number of times calculation was run.')
-- Counters for FTP
insert into Performance_Counters (Counter_Id, Object_Id, Name, Description) values (0, 5, 'Average (ms)', 'Average time to transfer file.')
insert into Performance_Counters (Counter_Id, Object_Id, Name, Description) values (1, 5, 'Last (ms)', 'Last time to transfer file.')
insert into Performance_Counters (Counter_Id, Object_Id, Name, Description) values (2, 5, 'Minimum (ms)', 'Minimum time to transfer file.')
insert into Performance_Counters (Counter_Id, Object_Id, Name, Description) values (3, 5, 'Maximum (ms)', 'Maximum time to transfer file.')
insert into Performance_Counters (Counter_Id, Object_Id, Name, Description) values (4, 5, 'Num Executions', 'Number of times files were transfered.')
-- Counters for Start/Stop
insert into Performance_Counters (Counter_Id, Object_Id, Name, Description) values (0, 6, 'Num Starts', 'Number of times service was started.')
insert into Performance_Counters (Counter_Id, Object_Id, Name, Description) values (1, 6, 'Num Stops', 'Number of times service was stoped.')
insert into Performance_Counters (Counter_Id, Object_Id, Name, Description) values (2, 6, 'Num Restarts', 'Number of times service was restarted (after is went away.).')
-- Counters for Event Models
insert into Performance_Counters (Counter_Id, Object_Id, Name, Description) values (0, 7, 'Average (ms)', 'Average time to run event model.')
insert into Performance_Counters (Counter_Id, Object_Id, Name, Description) values (1, 7, 'Last (ms)', 'Last time to run event model.')
insert into Performance_Counters (Counter_Id, Object_Id, Name, Description) values (2, 7, 'Minimum (ms)', 'Minimum time to run event model.')
insert into Performance_Counters (Counter_Id, Object_Id, Name, Description) values (3, 7, 'Maximum (ms)', 'Maximum time to run event model.')
insert into Performance_Counters (Counter_Id, Object_Id, Name, Description) values (4, 7, 'Num Executions', 'Number of times event model was run.')
-- Counters for Process Stats
insert into Performance_Counters (Counter_id, Object_Id, Name, Description) values (0, 8, 'CPU Time (User)', 'Total user CPU time in milliseconds.')
insert into Performance_Counters (Counter_id, Object_Id, Name, Description) values (1, 8, 'CPU Time (System)', 'Total System CPU time in milliseconds.')
insert into Performance_Counters (Counter_id, Object_Id, Name, Description) values (2, 8, 'Elapsed Time', 'Time the process has been running in seconds.')
insert into Performance_Counters (Counter_id, Object_Id, Name, Description) values (3, 8, 'Memory KB (Virtual)', 'Virtual memory of process in KB.')
insert into Performance_Counters (Counter_id, Object_Id, Name, Description) values (4, 8, 'Memory KB (Resident)', 'esident memory of process (Working Set) in KB.')
-- Counters for Historian
insert into Performance_Counters (Counter_Id, Object_Id, Name, Description) values (0, 9, 'Average (ms)', 'Average time to run stored procedure.')
insert into Performance_Counters (Counter_Id, Object_Id, Name, Description) values (1, 9, 'Last (ms)', 'Last time to run stored procedure.')
insert into Performance_Counters (Counter_Id, Object_Id, Name, Description) values (2, 9, 'Minimum (ms)', 'Minimum time to run stored procedure.')
insert into Performance_Counters (Counter_Id, Object_Id, Name, Description) values (3, 9, 'Maximum (ms)', 'Maximum time to run stored procedure.')
insert into Performance_Counters (Counter_Id, Object_Id, Name, Description) values (4, 9, 'Num Executions', 'Number of times stored procedure was run.')
-- Counters for Thread Pool
insert into Performance_Counters (Counter_Id, Object_Id, Name, Description) values (0,10, 'ThreadCnt)', 'Number of threads in the pool.')
insert into Performance_Counters (Counter_Id, Object_Id, Name, Description) values (1,10, 'JobCount', 'Number of jobs waiting to be executed.')
insert into Performance_Counters (Counter_Id, Object_Id, Name, Description) values (2,10, 'JobCount (Max)', 'Maximum number of jobs that were waiting to be executed.')
insert into Performance_Counters (Counter_Id, Object_Id, Name, Description) values (3,10, 'ThreadCnt (MaxInUse)', 'Maximum number of threads that ran work at the same time.')
insert into Performance_Counters (Counter_Id, Object_Id, Name, Description) values (4,10, 'ThreadCnt (Avg)', 'Average number of threads running work at the same time.  This only includes times when work was being executed.')
insert into Performance_Counters (Counter_Id, Object_Id, Name, Description) values (5,10, 'TimeWorking (%)', 'Percentage of time that at least one thread was working.  (Clock Time Spent Working)/(Total time pool was active).')
insert into Performance_Counters (Counter_Id, Object_Id, Name, Description) values (6,10, 'WorkDoneCount', 'Number of jobs executed in the pool.')

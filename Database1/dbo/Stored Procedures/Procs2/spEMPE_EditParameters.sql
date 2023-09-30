Create Procedure dbo.spEMPE_EditParameters
@Mode int, 
@AED int,
@Parameter_ID int, 
@HostName nvarchar(50), 
@User_ID int, 
@Value varchar(5000) = null, 
@UID int = null, 
@NewParmId int OUTPUT
AS
DECLARE @Insert_Id int
DECLARE @ECId Int
Declare @Ecvid Int
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_ID, 'spEMPE_EditParameters',
               	 convert(nVarChar(10), @Mode) + ','
 	  	 + convert(nVarChar(10), @AED) + ','
 	  	 + convert(nVarChar(10), @Parameter_Id) +','
 	  	 + @HostName + ','
 	  	 + Convert(nVarChar(10),@User_ID) + ','
 	  	 + Coalesce(@Value,'null') + ','
 	  	 + Coalesce(Convert(nVarChar(10),@UId),'null'),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
select @NewParmId = 0
IF @Value is Not Null
BEGIN
 	 IF @Parameter_ID = 103 and convert(int,@Value) Between 1 and 59
 	 BEGIN
 	  	 SET @Value = 60
 	 END
END
if @Mode = 1
BEGIN
   if @AED = 1 
     begin
 	 insert into Site_Parameters (Parm_Id,HostName,Value)  values (@Parameter_ID, @HostName, @Value)
        SELECT @NewParmId = Scope_Identity()
     end
   if @AED = 0 
 	 BEGIN
 	  	 update Site_Parameters 	 set Value = @Value 
 	  	  	 where Parm_ID = @Parameter_ID and HostName = @Hostname
 	  	 If @Parameter_ID = 440 -- tree and reason need to stay in sync - if tree is changed delete reason
 	  	  	 update Site_Parameters 	 set Value = 0 where Parm_ID = 441 and HostName = @Hostname
 	  	 If @Parameter_ID = 438 -- tree and reason need to stay in sync - if tree is changed delete reason
 	  	  	 update Site_Parameters 	 set Value = 0 where Parm_ID = 439 and HostName = @Hostname
  	  	 If @Parameter_ID = 438 -- tree and reason need to stay in sync - if tree is changed delete reason
 	  	  	 update Site_Parameters 	 set Value = 0 where Parm_ID = 439 and HostName = @Hostname
  	  	 IF @Parameter_ID in(603,604,607)
 	  	 BEGIN
 	  	  	 DECLARE @sInterval nVarChar(100),@sOffset  nVarChar(100)
 	  	  	 SELECT @sInterval = substring(value,1,255) FROM Site_Parameters WHERE parm_Id = 603 and HostName = ''
 	  	  	 SELECT @sOffset = substring(value,1,255) FROM Site_Parameters WHERE parm_Id = 604 and HostName = ''
 	  	  	 SELECT @sOffset = Convert(nVarChar(10),convert(int,@sOffset) * 60)
 	  	  	 EXECUTE dbo.spBF_OEEAggAddModel @Value,@sInterval,@sOffset
 	  	 END
 	  	 IF @Parameter_ID in (610) -- update System complete frequency in event
 	  	  	 BEGIN
 	  	  	  	 SELECT @ECId = ec_Id FROM Event_Configuration WHERE ED_Model_Id = 49300
 	  	  	  	 IF @ECId Is NOT Null
 	  	  	  	 SELECT @sInterval = substring(value,1,255) FROM Site_Parameters WHERE parm_Id = 610 and HostName = ''
 	  	  	  	 SET @sInterval = 'TINT:' + @sInterval
 	  	  	  	  	 select @Ecvid = ECV_iD fROM Event_Configuration_Data WHERE EC_Id = @ECId and ED_Field_Id = 2887
 	  	  	  	  	 IF (select substring(Value,1,255) From Event_Configuration_Values WHERE ECV_Id = @Ecvid) != @sInterval
 	  	  	  	  	  	 EXECUTE spEMSEC_PutECData   2887,@ECId, 0,@sInterval, 1,Null,@User_Id,@Ecvid
 	  	  	 END
     END
   if @AED = -1
     begin
 	 delete from Site_Parameters
 	 where Parm_ID = @Parameter_ID and HostName = @Hostname
     end
END
if @Mode = 2
BEGIN
    if @AED = 1 
     begin
 	 insert into User_Parameters (User_Id,Parm_Id,HostName,Value) values (@UID, @Parameter_ID, @HostName, @Value)
 	 SELECT @NewParmId = Scope_Identity()
     end
   if @AED = 0 
     begin
 	 update User_Parameters
 	 set Value = @Value where Parm_ID = @Parameter_ID and HostName = @Hostname and User_ID = @UID
     end
   if @AED = -1
     begin
 	 delete from User_Parameters
 	 where Parm_ID = @Parameter_ID and HostName = @Hostname and User_ID = @UID
     end
END
if @Mode = 3
BEGIN
   if @AED = 1 
     begin
 	  	 insert into Dept_Parameters (Dept_Id,Parm_Id,Parm_Required,Value) values (@UID, @Parameter_ID, 0, @Value)
 	  	 SELECT @NewParmId = 0
     end
   if @AED = 0 
     begin
 	  	 update Dept_Parameters 	 set Value = @Value where Parm_ID = @Parameter_ID  and Dept_Id = @UID
     end
   if @AED = -1
     begin
 	  	 delete from Dept_Parameters
 	  	 where Parm_ID = @Parameter_ID  and Dept_Id = @UID
     end
END
UPDATE Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id

/*
Declare @ECVId Int
Select @ECVId = 7838
execute spEM_WastePutECInputData Null,Null,Null,Null,Null,Null,Null,Null,Null,1,@ECVId output
*/
CREATE PROCEDURE  dbo.spEM_WastePutECInputData
 	 @EcId 	  	  	 Int,
 	 @PUId 	  	  	 Int,
 	 @Alias 	  	  	 nvarchar(50),
 	 @Trigger 	  	  	 Bit,
 	 @Tag 	  	  	  	 nvarchar(255),
 	 @Attribute 	  	 Int,
 	 @SamplingType 	  	 Int,
 	 @TimeOffset 	  	 Int,
 	 @Input_Precision 	 TinyInt,
 	 @User_Id  	  	  	 int,
 	 @ECVId 	  	  	 Int  OUTPUT
 AS
Declare @FieldId Int,
@Insert_Id int
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_WastePutECInputData',
 	  	  	 IsNull(Convert(nVarChar(10),@EcId),'Null') + ','  + 
 	  	  	 IsNull(Convert(nVarChar(10),@PUId),'Null') + ','  + 
 	  	  	 IsNull(@Alias,'Null') + ',' +
 	  	  	 IsNull(Convert(nVarChar(10),@Trigger),'Null') + ','  + 
 	  	  	 IsNull(@Tag,'Null') + ',' +
 	  	  	 IsNull(Convert(nVarChar(10),@Attribute),'Null') + ','  + 
 	  	  	 IsNull(Convert(nVarChar(10),@SamplingType),'Null') + ','  + 
 	  	  	 IsNull(Convert(nVarChar(10),@TimeOffset),'Null') + ','  + 
              	 IsNull(Convert(nVarChar(10),@User_Id),'Null') + ','  +
 	  	  	 IsNull(Convert(nVarChar(10),@ECVId),'Null') , dbo.fnServer_CmnGetDate(getUTCdate()))
SELECT @Insert_Id = Scope_Identity()
/*DELETE*/
If @EcId Is Null
 	 BEGIN
   	 Delete From event_configuration_data Where ECV_ID = @ECVId
   	 Delete From event_configuration_values Where ECV_ID = @ECVId
 	 RETURN
 	 END
/*ADD*/
If @ECVId Is Null
 	 BEGIN
 	 INSERT INTO Event_Configuration_Values(value) 
 	  	 VALUES ('PT:' + @Tag)
 	 SELECT @ECVId = IDENT_CURRENT('Event_Configuration_Values')
 	 INSERT INTO Event_Configuration_Data(EC_Id, ED_Field_Id, Alias , PU_Id, ECV_Id, ED_Attribute_Id, ST_Id, IsTrigger, Sampling_Offset, Input_Precision)
 	  	 VALUES (@EcId,2823,@Alias,@PUId,@ECVId,@Attribute,@SamplingType,@Trigger,@TimeOffset,@Input_Precision)
 	 RETURN
 	 END
/*UPDATE*/
UPDATE Event_Configuration_Data Set ED_Attribute_Id = @Attribute,
 	  	  	  	  	  	  	 ST_Id = @SamplingType,
 	  	  	  	  	  	  	 IsTrigger = @Trigger,
 	  	  	  	  	  	  	 Sampling_Offset = @TimeOffset,
 	  	  	  	  	  	  	 Input_Precision = @Input_Precision,
 	  	  	  	  	  	  	 Alias=@Alias
 	 WHERE ECV_Id = @ECVId and EC_Id = @EcId
UPDATE Event_Configuration_Values Set Value = 'PT:' + @Tag
 	 WHERE ECV_Id = @ECVId
UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id

Create Procedure dbo.spEMEC_GetWasteScriptModelData
@ECId int
AS
declare 	 @ModelType  	  	 Int,
 	  	 @WasteAmtScriptId  	 Int,
 	  	 @LocationScriptId  	 Int,
 	  	 @FaultScriptId  	 Int,
 	  	 @MeasScriptId  	  	 Int,
 	  	 @TypeScriptId  	  	 Int,
 	  	 @FaultMode 	  	 Int,
 	  	 @WasteMasterUnit 	 Int
Select CommentId = isnull(ec.Comment_Id,ed.comment_Id),Model_Desc = isnull(EC_Desc,'')
 	 from event_Configuration ec
 	 Join ed_Models ed On ec.ED_Model_Id = ed.ED_Model_Id
 Where Ec_Id = @ECId
/*Valid Sampling Types*/
Select ST_Id,ST_Desc
 From Sampling_type Where ST_Id  in (2,12,14,48)
/*Valid Attributes*/
Select ED_Attribute_Id,Attribute_Desc
 	 From ed_attributes
/* Input Data */
Select ecv.ECV_Id,
 	 ST_Id=isnull(ST_Id,12),
 	 IsTrigger=isnull(IsTrigger,0),
 	 Input_Precision=isnull(Input_Precision,0),
 	 Alias,
 	 Value=substring(isnull(convert(nvarchar(255),Value),''),4,255),
 	 ED_Attribute_Id=isnull(ED_Attribute_Id,1),
 	 Sampling_Offset=isnull(Sampling_Offset,0)
 From event_Configuration_Data ecd
 Join event_Configuration_Values ecv on ecv.ECV_Id = ecd.ECV_Id
 Where Ec_Id = @ECId and ED_Field_Id = 2823
Order by Alias
/*Model Type*/
Select @ModelType = convert(int,Convert(nVarChar(10),Value))
 From event_Configuration_Data ecd
 Join event_Configuration_Values ecv on ecv.ECV_Id = ecd.ECV_Id
 Where Ec_Id = @ECId and ED_Field_Id  =  2822
Select @WasteAmtScriptId = ECV_Id
 From event_Configuration_Data ecd
 Where Ec_Id = @ECId and ED_Field_Id  =  2824
Select @LocationScriptId = ECV_Id
 From event_Configuration_Data ecd
 Where Ec_Id = @ECId and ED_Field_Id  =  2825
Select @TypeScriptId = ECV_Id
 From event_Configuration_Data ecd
 Where Ec_Id = @ECId and ED_Field_Id  =  2827
Select @MeasScriptId = ECV_Id
 From event_Configuration_Data ecd
 Where Ec_Id = @ECId and ED_Field_Id  =  2828
Select ModelType=@ModelType,
 	 WasteAmtScriptId = @WasteAmtScriptId,
 	 LocationScriptId=@LocationScriptId,
 	 MeasScriptId=@MeasScriptId,
 	 TypeScriptId=@TypeScriptId
/* Scripts by fault Locations - PU_Id = Location */
Select @WasteMasterUnit = PU_Id 
from  event_Configuration
 Where Ec_Id = @ECId
Select pu.PU_Id,ScriptId = e.ECV_Id,pu.PU_Desc
 From Prod_Units pu
 Left Join event_Configuration_Data e on Ec_Id = @ECId and ED_Field_Id = 2826 and pu.PU_Id = e.pu_Id
 Where (pu.pu_Id = @WasteMasterUnit or pu.master_Unit = @WasteMasterUnit) and pu.Waste_Event_Association in(1, 2)
/* Usable Faults */
Select WEFault_Value,Source_PU_Id
 from Waste_Event_Fault 
Where PU_Id = @WasteMasterUnit and Source_PU_Id is not Null

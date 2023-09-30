Create Procedure dbo.spEC_PreLoadByUnit
 	 @UnitId Int
AS
  Create Table   #UnitEventData ( 	 UnitId Int,
 	  	  	  	 UnitName nvarchar(50),
 	  	  	  	 InputId Int,
 	  	  	  	 InputName  nvarchar(50),
 	  	  	  	 Event_Subtype  Int,
 	  	  	  	 EventId Int Null,
 	  	  	  	 PositionName  nvarchar(50),
 	  	  	  	 PEIP_Id 	 Int,
 	  	  	  	 Input_Order Int,
 	  	  	  	 HideInput 	 TinyInt,
 	  	  	  	 AllowManualMovement TinyInt,
 	  	  	  	 HideWhenBOMEmpty 	 TinyInt)
  Declare @PathId Int
  Select @PathId = Null
  Select @PathId =  Path_Id 
 	 From PrdExec_Path_Unit_Starts
 	 Where End_Time is Null and PU_Id = @UnitId
If @PathId is not null /* if not defined at the path level default back to the unit level */
  if (Select Count(*) from PrdExec_Path_input_Sources where Path_Id = @PathId and  PU_Id = @UnitId) = 0 
 	 Select @PathId = Null
If @PathId is null
  Begin
    Insert Into #UnitEventData(UnitId,UnitName,InputId,InputName,Event_Subtype,EventId,PositionName,PEIP_Id,Input_Order,HideInput,AllowManualMovement,HideWhenBOMEmpty)
      Select  Distinct   UnitId = @UnitId,UnitName = pu.PU_Desc,InputId 	 = pei.PEI_Id,
 	  	 InputName = Input_Name, 	 Event_SubType = Event_Subtype_Id,Null,PositionName = PEIP_Desc,
 	  	 PEIP_Id  = PEIP_Id, 	 Input_Order = Input_Order,0,1,0
 	   From  PrdExec_Input_Positions,prdexec_Inputs pei
 	   Join PrdExec_input_Sources pe on pei.Pei_Id = pe.Pei_Id
 	   Join Prod_Units pu ON pu.PU_ID = pei.Pu_Id
 	  Where  pei.Pu_Id = @UnitId Order By  InputId  
  End
Else
  Begin
    Insert Into #UnitEventData(UnitId,UnitName,InputId,InputName,Event_Subtype,EventId,PositionName,PEIP_Id,Input_Order,HideInput,AllowManualMovement,HideWhenBOMEmpty)
      Select  Distinct   UnitId = @UnitId,UnitName = pu.PU_Desc,InputId 	 = pei.PEI_Id,
 	  	 InputName = Input_Name, 	 Event_SubType = pei.Event_Subtype_Id,Null,PositionName = PEIP_Desc,
 	  	 PEIP_Id  = PEIP_Id, 	 Input_Order = Input_Order,Hide_Input=Coalesce(Hide_Input,0),Allow_Manual_Movement= coalesce(Allow_Manual_Movement,1),0
 	   From  PrdExec_Input_Positions,prdexec_Inputs pei
 	   Join PrdExec_Path_input_Sources pe on pei.Pei_Id = pe.Pei_Id and pe.path_Id = @PathId
 	   Left Join PrdExec_Path_Inputs pepi on pepi.path_Id = pe.path_Id
 	   Join Prod_Units pu ON pu.PU_ID = pei.Pu_Id
 	   Where  pei.Pu_Id = @UnitId Order By  InputId  
  End
 Select  u.UnitId,u.UnitName,u.InputId,u.InputName,u.Event_SubType,EventId = pie.event_Id,u.PositionName,u.HideInput,u.AllowManualMovement,u.HideWhenBOMEmpty
    From #UnitEventData u
    Left  Join PrdExec_Input_Event pie  On pie.PEI_Id = inputid and pie.PEIP_Id = u.PEIP_Id
  Order By UnitId,Input_Order,InputId,u.PEIP_Id
Drop Table #UnitEventData

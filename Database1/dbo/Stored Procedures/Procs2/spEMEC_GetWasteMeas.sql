Create Procedure dbo.spEMEC_GetWasteMeas
@PU_Id int,
@User_Id int
AS
Declare @Insert_Id int
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEMEC_GetWasteMeas',
             Convert(nVarChar(10),@PU_Id) + ','  + 
             Convert(nVarChar(10),@User_Id), dbo.fnServer_CmnGetDate(getUTCdate()))
SELECT @Insert_Id = Scope_Identity()
If (SELECT Count(*)
FROM Waste_Event_Meas
where PU_Id = @PU_Id) = 0
 	 Begin 	  	 
 	  	 Declare @WEMT_Name nVarChar(100) 	  	 
 	  	 select @WEMT_Name = es.dimension_x_eng_units
 	  	 from event_subtypes es
 	  	 join event_configuration ec on ec.event_subtype_id = es.event_subtype_id
 	  	 where ec.pu_id = @PU_Id and ec.et_id = 1
 	  	 exec spEMEC_UpdateWasteMeas NULL, @WEMT_Name, 1, NULL, @PU_Id, @User_Id
 	 End
SELECT WEMT_Id, WEMT_Name, Conversion, Conversion_Spec
FROM Waste_Event_Meas
where PU_Id = @PU_Id
order by WEMT_Name
UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id

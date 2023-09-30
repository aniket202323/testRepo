--   spEMSEC_GetAvailableModels 1,null,1
Create Procedure dbo.spEMSEC_GetAvailableModels
@ET_Id int,
@BatchLicenseOnly int,
@AllowBatch int
as
DECLARE @Unavailable TABLE (ModelId INT)
INSERT INTO @Unavailable (ModelId) VALUES (49000)
IF @ET_Id in (16,17,18)
BEGIN
 	 INSERT INTO @Unavailable (ModelId)
 	  	 SELECT ED_Model_Id 
 	  	  	 FROM ed_models
 	  	  	 WHERE et_id = @ET_Id and ED_Model_Id < 50000
END
IF  @BatchLicenseOnly = 1  and @ET_Id = 1
BEGIN
 	 INSERT INTO @Unavailable (ModelId)
 	  	 SELECT ED_Model_Id 
 	  	  	 FROM ed_models
 	  	  	 WHERE et_id = 1 and ED_Model_Id != 100
END
IF @AllowBatch = 0
BEGIN
 	 INSERT INTO @Unavailable (ModelId) VALUES (100)
END
SELECT [KEY] = ed_model_id, [Model Number] = model_num, [Model Description] = model_desc, [Derived From] = Derived_From
 	 from ed_models
 	 where (ed_models.et_id = @ET_Id) 
 	 --or (Derived_From  Between 600 and 607 and  @ET_Id = 14)) --UDE = 14, Generic = 15 (Defect #20738) (changed for ticket 27263 to only allow derived)
 	 --(Defect #92326)(To comment Derived from condition) the list of models returned should contain UDEs only for 50000 models 
 	 and ED_Model_Id Not in (SELECT ModelId FROM @Unavailable) And (Is_Active = 1 or Is_Active is Null)
 	 order by Model_Num

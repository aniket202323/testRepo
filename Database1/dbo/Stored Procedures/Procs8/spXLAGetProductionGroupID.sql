Create Procedure dbo.spXLAGetProductionGroupID
 	 @Descr varchar(50)
AS
  SELECT  pug.PUG_Id
    FROM  PU_Groups pug
   WHERE  pug.PUg_Desc = @Descr

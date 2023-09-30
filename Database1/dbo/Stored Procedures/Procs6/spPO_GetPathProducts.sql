

CREATE PROCEDURE dbo.spPO_GetPathProducts
@Path_Id bigint
  AS
/***********************************************************/
/******** Copyright 2004 GE Fanuc International Inc.********/
/****************** All Rights Reserved ********************/
/***********************************************************/
IF NOT EXISTS(SELECT 1 FROM PrdExec_Paths WHERE Path_Id = @Path_Id )
BEGIN
	--SELECT  Error = 'ERROR: Valid User Required'
		SELECT Error = 'ERROR: Valid Path Id Required', Code = 'ResourceNotFound', ErrorType = 'PathNotFound', PropertyName1 = 'PathId', PropertyName2 = @Path_Id, PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
	RETURN
END
/* check if PathId is valid or not, if not throw error */
	select PB.Prod_Id, PB.Prod_Code, PB.Prod_Desc
	from PrdExec_Path_Products
	    JOIN Products_Base PB ON PB.Prod_Id = PrdExec_Path_Products.Prod_Id
	where PrdExec_Path_Products.Path_Id = @Path_Id;


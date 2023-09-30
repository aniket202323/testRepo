
CREATE PROCEDURE [dbo].[spPS_ProductToExecutionPathAssociation]
@Prod_Id      int = null,
@Path_Id      int = null,
@User_Id      int = 1,
@paramType    nVarChar(10)

 AS	
	    IF NOT EXISTS(SELECT 1 FROM Products WHERE Prod_Id = @Prod_Id)
		BEGIN
			SELECT Error = 'Product Id is not found to update' , 'EPS1091' as Code
			RETURN
		END

		IF NOT EXISTS(SELECT 1 FROM Prdexec_Paths WHERE Path_Id = @Path_Id)
		BEGIN
			SELECT Error = 'Production Execution Path with Id is not found to update', 'EPS1092' as Code
			RETURN
		END
	
		IF(@paramType ='CREATE')
			BEGIN
				-- Calling Core Sproc to Associate product to Execution Path
			    EXECUTE dbo.spEMEPC_PutPathProducts @Path_Id, @Prod_Id, @User_Id
			END
		ELSE IF(@paramType='DELETE')
			BEGIN
				DECLARE @PeppId int
				SET @PeppId = (SELECT TOP 1 PEPP_Id from PrdExec_Path_Products WHERE Path_Id = @Path_Id AND Prod_Id = @Prod_Id)
				
				EXECUTE dbo.spEMEPC_PutPathProducts @Path_Id, @Prod_Id, @User_Id, @PeppId
			END

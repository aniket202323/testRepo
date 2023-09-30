
CREATE PROCEDURE [dbo].[spPS_GetProductExecutionPaths]
@Prod_Id      int = null,
@User_Id      int = 1

  AS
		IF NOT EXISTS(SELECT 1 FROM Products WHERE Prod_Id = @Prod_Id)
		BEGIN
			SELECT Error = 'Product Not Found To Update', 'EPS1093' as Code
			RETURN
		END

		BEGIN
			-- SELECT * FROM PrdExec_Path_Products WHERE Prod_Id = @Prod_Id
			
			SELECT pep.Path_Id, pep.Path_Code, pep.Path_Desc, pep.PL_Id FROM PrdExec_Path_Products pepp
                  LEFT JOIN PrdExec_Paths pep ON pep.Path_Id = pepp.Path_Id 
                  WHERE pepp.Prod_Id = @Prod_Id
                  
			
		END
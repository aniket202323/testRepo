CREATE procedure [dbo].[spSDK_AU_PathProductAssignment]
@AppUserId int,
@Id int OUTPUT,
@Department varchar(200) ,
@DepartmentId int ,
@PathCode varchar(200) ,
@PathId int ,
@ProductCode nvarchar(25) ,
@ProductId int ,
@ProductionLine nvarchar(50) ,
@ProductionLineId int 
AS
DECLARE @ReturnMessages TABLE(msg VarChar(100))
DECLARE @OldPathId Int,@OldProductId Int
EXEC dbo.spSDK_AU_LookupIds 	 
 	  	  	  	 @Department 	 OUTPUT,
 	  	  	  	 @DepartmentId OUTPUT, 	 
 	  	  	  	 @ProductionLine OUTPUT, 	 
 	  	  	  	 @ProductionLineId OUTPUT
IF @Id Is Not Null
BEGIN
 	 IF Not Exists(SELECT 1 FROM PrdExec_Path_Products WHERE PEPP_Id = @Id)
 	 BEGIN
 	  	 SELECT 'Production Execution Path not found for update'
 	  	 RETURN(-100)
 	 END
 	 SELECT @OldPathId = Path_Id, @OldProductId = Prod_Id
 	  	 FROM PrdExec_Path_Products
 	  	 WHERE PEPP_Id = @Id
 	 IF @OldPathId <> @PathId Or @OldProductId <> @ProductId
 	 BEGIN
 	  	 UPDATE PrdExec_Path_Products SET Path_Id = @PathId,Prod_Id = @ProductId
 	  	  	 WHERE PEPP_Id = @Id
 	  	 RETURN(1)
 	 END
END
ELSE
BEGIN
 	 SELECT @Id = PEPP_Id 
 	  	 FROM PrdExec_Path_Products 
 	  	 WHERE Path_Id = @PathId And Prod_Id = @ProductId
 	 IF @Id Is Not Null
 	 BEGIN
 	  	  	 SELECT 'Data Source already exists - add failed'
 	  	  	 RETURN(-100)
 	 END
END
INSERT INTO @ReturnMessages(msg)
 	 EXECUTE spEM_IEImportProdExecPathProducts @PathCode,@ProductCode,@AppUserId
IF EXISTS(SELECT 1 FROM @ReturnMessages)
BEGIN
 	 SELECT msg FROM @ReturnMessages
 	 RETURN(-100)
END
SELECT @Id = PEPP_Id
 	 FROM PrdExec_Path_Products
 	 WHERE Path_Id = @PathId And Prod_Id = @ProductId
Return(1)

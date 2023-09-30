
CREATE PROCEDURE [dbo].[spSecurity_AssignmentDeleteOperations]

@AssignmentId int  = null		/*	assignment id	*/

AS

BEGIN TRANSACTION
Declare @chck int;
 
			  IF @AssignmentId is Null
			 	 BEGIN
					select @chck =1
			 	  	  SELECT Error = 'Assignment id required','ESS1029' as Code					  
			 	 END
			 	 
			  IF NOT EXISTS(SELECT 1 FROM security.Assignments WHERE id = @AssignmentId) and  @AssignmentId is not Null
			 	 BEGIN
					 select @chck =1
			 	  	 SELECT Error = 'Assignment Id not found','ESS1021' as Code					 
		 		 END

			  IF @AssignmentId is Not Null And @chck is null
				begin
					delete from security.Assignments WHERE id = @AssignmentId
					delete from security.Assignment_Role_Details WHERE assignment_id = @AssignmentId
					delete from security.Assignment_Group_Details WHERE assignment_id = @AssignmentId
					delete from security.Line_Resource_Details WHERE assignment_id = @AssignmentId
					delete from security.Units_Resource_Details WHERE assignment_id = @AssignmentId
					delete from security.Product_Resource_Details WHERE assignment_id = @AssignmentId
					delete from security.Product_Family_Resource_Details WHERE assignment_id = @AssignmentId
					delete from security.Site_Resource_Details WHERE assignment_id = @AssignmentId
					SELECT Success = 'Assignment deleted'
				end			 
	

	
COMMIT TRANSACTION;

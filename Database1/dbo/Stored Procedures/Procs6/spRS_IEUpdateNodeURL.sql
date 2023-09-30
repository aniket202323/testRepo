CREATE PROCEDURE dbo.spRS_IEUpdateNodeURL
@Node_Id int,
@URL 	     VarChar(7000) = NULL
AS
Update Report_Tree_Nodes Set
URL = @URL
Where Node_Id = @Node_Id

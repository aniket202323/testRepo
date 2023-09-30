CREATE PROCEDURE dbo.spRS_IEgetGroupInfo
 	 @Group_Id 	 int
AS
/*  For use with Import/Export of Report package
    MSI/MT 8-9-2000
*/
SELECT 	 RPG.* 
FROM 	 Report_Parameter_groups RPG
WHERE 	 RPG.Group_Id = @Group_Id

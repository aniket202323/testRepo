CREATE PROCEDURE dbo.spSDK_GetTransCharLinks
 	 @TransId 	  	  	 INT,
 	 @ChildId 	  	  	 INT,
 	 @ParentDesc 	  	 nvarchar(50) 	 OUTPUT,
 	 @OldParent 	  	 nvarchar(50) 	 OUTPUT
AS
DECLARE 	 @ParentId 	  	 INT,
 	  	  	 @OldParentId 	 INT
SELECT 	 @ParentId = CASE 
 	  	  	  	  	  	  	  	 WHEN tcl.Trans_Id IS NOT NULL THEN tcl.To_Char_Id 
 	  	  	  	  	  	  	  	 ELSE c.Derived_From_Parent
 	  	  	  	  	  	  	 END,
 	  	  	 @OldParentId = c.Derived_From_Parent
 	 FROM 	 Characteristics c 	  	 LEFT JOIN
 	  	  	 Trans_Char_Links tcl 	 ON (c.Char_Id = tcl.From_Char_Id AND
 	  	  	  	  	  	  	  	  	  	  	  Trans_Id = @TransId)
 	 WHERE 	 c.Char_Id = @ChildId
SELECT 	 @ParentDesc = NULL
SELECT 	 @ParentDesc = Char_Desc
 	 FROM 	 Characteristics
 	 WHERE 	 Char_Id = @ParentId
SELECT 	 @OldParent = NULL
SELECT 	 @OldParent = Char_Desc
 	 FROM 	 Characteristics
 	 WHERE 	 Char_Id = @OldParentId

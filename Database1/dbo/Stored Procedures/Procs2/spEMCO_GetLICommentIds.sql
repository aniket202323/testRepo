Create Procedure dbo.spEMCO_GetLICommentIds
@OID integer,
@User_Id int
AS
SELECT Order_Line_Id, Comment_Id
FROM Customer_Order_Line_Items
WHERE Order_Id = @OID
AND Comment_Id IS NOT NULL

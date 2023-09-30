CREATE PROCEDURE dbo.spEM_CreateChildSpecs
  @ParentId INT,
  @ArraySize INT,
  @DataTypeId INT,
 	 @UserId 	  	  	 Int
AS 
-- Return Codes: 0 = Success, 1 = Can't create specification.
DECLARE
  @SpecPrecision INT,
  @PropId INT,
  @SpecDesc nVarChar(100),
  @Tag nvarchar(50),
  @EngUnits nvarchar(50),
  @ExtendedInfo nvarchar(50),
  @ExternalLink nvarchar(50),
  @CommentId INT,
  @SpecOrder INT,
  @ChildOrder nVarChar(10),
  @Counter INT,
 	 @NewSpecDesc 	 nVarChar(100),
 	 @NewSpecId 	  	 Int,
  @CurArraySize INT
IF @ArraySize IS NULL SET @ArraySize = 0
-- Get fields of parent spec
SELECT
  @PropId = Prop_Id,
  @SpecDesc = Spec_Desc,
  @SpecPrecision = Spec_Precision,
  @Tag = Tag,
  @EngUnits = Eng_Units,
  @ExtendedInfo = Extended_Info,
  @ExternalLink = External_Link,
  @CommentId = Comment_Id,
  @CurArraySize = Array_Size
FROM Specifications WHERE Spec_Id = @ParentId
Select @CurArraySize = isnull(@CurArraySize,0)
Select @SpecPrecision = isnull(@SpecPrecision,0)
-- Parent not found
IF @SpecDesc IS NULL
  RETURN 1
-- Delete extra child specs as new array size is smaller
IF @ArraySize < @CurArraySize
BEGIN
  DECLARE @SpecId INT
  DECLARE SpecIdCursor CURSOR FOR
    SELECT Spec_Id FROM Specifications
    WHERE  Parent_Id = @ParentId ORDER BY Spec_Desc
  OPEN SpecIdCursor
  FETCH NEXT FROM SpecIdCursor INTO @SpecId
  SET @Counter = 1
  WHILE @@FETCH_STATUS = 0
  BEGIN
-- Delete child specs that are not needed
    IF @Counter > @ArraySize
    BEGIN
      UPDATE Specifications SET Comment_Id = NULL WHERE Spec_Id = @SpecId
      EXECUTE spEM_DropSpec @SpecId, @UserId
    END
    FETCH NEXT FROM SpecIdCursor INTO @SpecId
    SET @Counter = @Counter + 1
  END
  CLOSE SpecIdCursor
  DEALLOCATE SpecIdCursor
END
-- Add more child specs as new array size is greater
IF @ArraySize > @CurArraySize
BEGIN
  SELECT @SpecOrder = MAX(Spec_Order) + 1 FROM Specifications WHERE Prop_Id = @PropId
  SET @Counter = @CurArraySize + 1
  WHILE @Counter <= @ArraySize
  BEGIN
    SET @ChildOrder = CONVERT(VARCHAR(5), @Counter)
    IF LEN(@ChildOrder) = 1 SET @ChildOrder =  '0' + @ChildOrder
    IF LEN(@ChildOrder) = 2 SET @ChildOrder =  '0' + @ChildOrder
    Select @NewSpecDesc =  @SpecDesc + ':' + @ChildOrder
 	  	 Execute spEM_CreateSpec @NewSpecDesc,@PropId,@DataTypeId,@SpecPrecision,@UserId,@NewSpecId OUTPUT,@SpecOrder OUTPUT
 	  	 Update Specifications set Parent_Id = @ParentId
 	  	  	 Where Spec_Id = @NewSpecId
    SET @Counter = @Counter + 1
  END
END
-- Update all child specs
UPDATE Specifications SET Spec_Precision = @SpecPrecision, Tag = @Tag, Eng_Units = @EngUnits, Data_Type_Id = @DataTypeId,
  Prop_Id = @PropId, Extended_Info = @ExtendedInfo, External_Link = @ExternalLink, Comment_Id = @CommentId
WHERE Parent_Id = @ParentId
-- Update array size
IF @ArraySize = 0 SET @ArraySize = NULL
UPDATE Specifications
SET Array_Size = @ArraySize
WHERE Spec_Id = @ParentId
SELECT Spec_Id, Spec_Order, Spec_Desc FROM Specifications
WHERE Parent_Id = @ParentId ORDER BY Spec_Desc
RETURN 0

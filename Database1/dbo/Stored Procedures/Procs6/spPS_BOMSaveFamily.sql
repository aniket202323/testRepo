
CREATE PROCEDURE [dbo].[spPS_BOMSaveFamily]
 	 @GroupId     INT = NULL,
 	 @CommentId   INT = NULL,
 	 @Description NVARCHAR(50),
	 @ParamType   NVARCHAR(10),
 	 @FamilyId	  INT OUTPUT
AS
/*---------------------------------------------------------------------------------------------------------------------
    This SP is a wrapper around the existing "spEM_BOMSaveFamily" SP, to allow the "product-service" to create BOM Family records
  
    Date             Story/Defect   Remarks
    15-Jul-2020       US428609      Initial Development (CREATE)

---------------------------------------------------------------------------------------------------------------------
    NOTES:
        - Currently only Supports Creating a BOM Family.
        - The "spEM_BOMSaveFamily" SP will delete a BOM Family and its comments if an empty string is passed in to the "@Desc" parameter .
          We therefore need to make sure that we don't pass an empty string in.
        - If a value is passed in to "@Id" to pass through to "@TEMP_Id", an existing BOM Family with the id value would be updated.
        - We will therefore block those actions from happening.
        - @ParamType determines what action we will take
        - Was going to name this "CreateUpdateDelete..." but at time of writing, there is already a "spEM_BOMSaveFamily"

    TODO:
        - Add UPDATE and DELETE sections as required.

---------------------------------------------------------------------------------------------------------------------*/

	SET NOCOUNT ON;

	/* DECLARATIONS */
    DECLARE
            @PARAMCREATE     NVARCHAR(10) = 'CREATE',
            @PARAMUPDATE     NVARCHAR(10) = 'UPDATE',
            @PARAMDELETE     NVARCHAR(10) = 'DELETE',
			@tempFamilyId    INT          = NULL;

	/* CREATE the new BOM Family */
    IF (@ParamType = @PARAMCREATE)
 	  BEGIN		

		  -- Run the SP, passing the NULL @tempMasterId in, so that "spEM_BOMSaveFamily" doesn't try to do an update.
		  EXECUTE dbo.spEM_BOMSaveFamily 
						@Group = NULL,  
						@Comment = NULL, 
						@Desc = @Description,
						@Id = @tempFamilyId OUTPUT

		  -- Pass the new FamilyId back out of the SP
            SET @FamilyId = @tempFamilyId;
      END;


CREATE PROCEDURE [dbo].[spPS_BOMSaveMaster]
 	 @FamilyId    INT,
     @IsActive    BIT = NULL,
     @GroupId     INT = NULL,
     @CommentId   INT = NULL,
 	 @Description NVARCHAR(50),
 	 @MasterId    INT OUTPUT,
     @ParamType   NVARCHAR(10)
AS


/*---------------------------------------------------------------------------------------------------------------------
    This SP is a wrapper around the existing "spEM_BOMSave" SP, to allow the "product-service" to create BOM Master records
  
    Date         Ver/Build   Author              Story/Defect  Remarks
    15-Jul-2020  001         Dan Stephens        US429073      Initial Development (CREATE)

---------------------------------------------------------------------------------------------------------------------
    NOTES:
        - Currently only Supports Creating a BOM Master.
        - The "spEM_BOMSave" SP will delete a BOM Master and its comments if an empty string is passed in to the "@Desc" parameter.
          We therefore need to make sure that we don't pass an empty string in.
        - If a value is passed in to "@MasterId" to pass through to "@Id", an existing BOM Master with the id value would be updated.
        - We will therefore block those actions from happening.
        - @ParamType determines what action we will take
        - Was going to name this "CreateUpdateDelete..." but at time of writing, there is already a "spPS_BOMSaveFamily"

    QUESTIONS:
        - 
    
    TODO:
        - Add UPDATE and DELETE sections as required.

---------------------------------------------------------------------------------------------------------------------*/

    SET NOCOUNT ON;

    /* DECLARATIONS */
    DECLARE @tempDescription NVARCHAR(50) = 'NotEmpty',
            @tempMasterId    INT          = NULL,
            @PARAMCREATE     NVARCHAR(10) = 'CREATE',
            @PARAMUPDATE     NVARCHAR(10) = 'UPDATE',
            @PARAMDELETE     NVARCHAR(10) = 'DELETE';



    /* CREATE the BOM Master */
    IF (@ParamType = @PARAMCREATE)
        BEGIN

            -- Stop an empty @description being passed in just so that.
            IF (@Description = '' OR @Description = NULL)
                SET @Description = @tempDescription;

    
            -- Run the SP, passing the NULL @tempMasterId in, so that "spEM_BOMSave" doesn't try to do an update.
            EXECUTE spEM_BOMSave @Family  = @FamilyId,
                                 @Active  = NULL,
                                 @Group   = NULL,
                                 @Comment = NULL,
                                 @Desc    = @Description,
                                 @Id      = @tempMasterId OUTPUT;

            -- Pass the new MasterId back out of the SP
            SET @MasterId = @tempMasterId;
        END;


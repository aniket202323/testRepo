
CREATE PROCEDURE [dbo].[spPS_BOMSaveFormulationProduct]
 	 @BOM_Formulation_Id  INT,
     @ProductId           INT,
     @PUId                INT = NULL,
     @ParamType           NVARCHAR(10)
AS


/*---------------------------------------------------------------------------------------------------------------------
    This SP is a wrapper around the existing "spPS_BOMSaveFormulationProduct" SP, to allow the "product-service" to add Products to BOM Formulations
  
    Date         Ver/Build   Author              Story/Defect  Remarks
    07-Sep-2020  001         Dan Stephens                      Initial Development (CREATE)

---------------------------------------------------------------------------------------------------------------------
    NOTES:
        - Currently only Supports Creating a BOM Formulation Product record.
        - @ParamType determines what action we will take

    QUESTIONS:
        - 
    
    TODO:
        - Add UPDATE and DELETE sections as required.

---------------------------------------------------------------------------------------------------------------------*/

    SET NOCOUNT ON;

    /* DECLARATIONS */
    DECLARE @PARAMCREATE     NVARCHAR(10) = 'CREATE',
            @PARAMUPDATE     NVARCHAR(10) = 'UPDATE',
            @PARAMDELETE     NVARCHAR(10) = 'DELETE';



    /* CREATE the BOM Formulation Product record */
    IF (@ParamType = @PARAMCREATE)
        BEGIN

    
            -- Run the SP.
            EXECUTE dbo.spEM_BOMSaveFormulationProduct @form = @BOM_Formulation_Id,
                                                       @prod = @ProductId,
                                                       @unit = NULL;

        END;


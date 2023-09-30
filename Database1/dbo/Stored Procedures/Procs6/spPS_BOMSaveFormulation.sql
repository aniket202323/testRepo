
CREATE PROCEDURE dbo.spPS_BOMSaveFormulation
    @BOMFormulationCode NVARCHAR(25)  = NULL,
    @BOMFormulationDesc NVARCHAR(50),
    @BOMId              INT,
    @EffectiveDate      DATETIME      = NULL, 
    @ExpirationDate     DATETIME      = NULL,
    @Revision           INT           = NULL,
    @Status             NVARCHAR(25)  = NULL,
    @UnitId             INT           = NULL,
    @Precision          INT           = NULL,
    @Quantity           FLOAT         = NULL,
    @Created_by         NVARCHAR(50)  = NULL,
    @Modified_by        NVARCHAR(50)  = NULL,
    @UserId             INT,
    @BOM_Formulation_Id INT           OUTPUT,
    @ParamType          NVARCHAR(10) 

AS

/*---------------------------------------------------------------------------------------------------------------------
    This SP creates/updates BOM Formulation header details. It also creates Product links to BOM Formulation
  
    Date         Ver/Build   Author               Story/Defect       Remarks
    16-Jun-2020  001         Sireesha                                Initial Development
    12-Aug-2020  002         Dan Stephens         DE139882           Added "modified" parameters, and pushed these to the insert.
                                                                        Formatting for readability
    28-Aug-2020  003         Suman Kotagiri                          Updated to INSERT into "dbo.Bill_Of_Material_Formulation_Revision"
                                                                        instead of into "dbo.Bill_Of_Material_Formulation_Details"
    03-Sep-2020  004         Dan Stephens                            Renamed SP from "spPS_CreateBomFormulation" to "spPS_BOMSaveFormulation"
                                                                        Updated to take a @paramType parameter to determine CREATE/UPDATE
    07-Sep-2020  005         Dan Stephens                            Fix for DELETE    
    08-Sep-2020  006         Dan Stephens                            Removed call to create products
    14-Sep-2020  007         Dan Stephens                            Added Transaction and Error handling
    17-Sep-2020  008         Dan Stephens         DE143524           Added Error output to DELETE, when Bom_Formulation_Id does not exist
    25-Sep-2020  009         Dan Stephens         DE144131           Updated "Modified_On" date to be set by DB Function, instead of incoming parameter
    07-Oct-2020  010         Dan Stephens         DE140288           Added/updated validation on BOM Formulation Id in UPDATE and DELETE.
                                                                     Added Error Code/Messages Variables for easier tracking and re-use.
                                                                     Added validation on Engineering Unit Id and BOM Master Id in CREATE and UPDATE
    13-Oct-2020  011         Suman                                   Update Expiration date to NULL should be supported.
    15-Oct-2020  012         Dan Stephens         US428620           ON UPDATE, create "Bill_Of_Material_Formulation_Revision" record if none exist
    06-Nov-2020  013         Dan Stephens         DE146768           Updated from VARCHAR to NVARCHAR to match the core SP (spEM_BOMSaveFormulation), and to enable Unicode.

---------------------------------------------------------------------------------------------------------------------
    PARAMETERS:
        - 

    Return Codes:
        returns:    "BOM_Formulation_Id" of BOM Formulation

    NOTES:
        - Historic details of modifications before ver 002 taken from Git commit details.
        - This SP creates/updates BOM formulations.
        - The base SP requires a UserID to be passed in to perform updates. Added this in.


    TODO:
        - Update the SP parameters to be more consistent?
        - At the moment there will be a 1to1 link between Formulation and Revision.
          Later on, will need to update this SP to handle multiple revisions of a Formulation.
        - add ability to add "Comment" later?
        - review to confirm which fields we will allow to be updated.
        - Check what values we need to "RETURN" when doing a create/update/delete
    
---------------------------------------------------------------------------------------------------------------------*/


BEGIN

    SET XACT_ABORT ON;
    SET NOCOUNT    ON;

    /* DECLARATIONS */
    DECLARE @tempDescription        NVARCHAR(50)  = 'NotEmpty',
            @tempComment            NVARCHAR(MAX) = '',
            @tempBomFormulationId   INT           = NULL,
            @tempMasterTemplate     INT           = NULL,
            @PARAMCREATE            NVARCHAR(10)  = 'CREATE',
            @PARAMUPDATE            NVARCHAR(10)  = 'UPDATE',
            @PARAMDELETE            NVARCHAR(10)  = 'DELETE';


    /* ERROR MESSAGES */
    DECLARE @FORMULATION_ID_NOT_EXIST_MSG  NVARCHAR(50) = 'BOM Formulation Id does not exist',
            @FORMULATION_ID_NOT_EXIST_CODE NVARCHAR(50) = 'EPS2101',
            @BOM_MASTER_ID_NOT_EXIST_MSG   NVARCHAR(50) = 'Invalid BOM Master Id',
            @BOM_MASTER_ID_NOT_EXIST_CODE  NVARCHAR(50) = 'EPS2105',
            @ENG_UNIT_ID_NOT_EXIST_MSG     NVARCHAR(50) = 'Unit of Measure Id does not exist',
            @ENG_UNIT_ID_NOT_EXIST_CODE    NVARCHAR(50) = 'EPS2107';



    /* CREATE the BOM Formulation */
    IF (@ParamType = @PARAMCREATE)
        BEGIN TRY

            -- VALIDATION - pre create
            -- make sure that the incoming Eng Unit Id exists
            IF NOT EXISTS (SELECT 1 FROM dbo.Engineering_Unit engunit WHERE engunit.Eng_Unit_Id = @UnitId)
                BEGIN
                    SELECT @ENG_UNIT_ID_NOT_EXIST_MSG  AS Error, @ENG_UNIT_ID_NOT_EXIST_CODE AS Code;
                    RETURN;
                END;
            -- make sure that the incoming BOM Master Id (BOMId) exists
            IF NOT EXISTS (SELECT 1 FROM dbo.Bill_Of_Material bommas WHERE bommas.BOM_Id = @BOMId)
                BEGIN
                    SELECT @BOM_MASTER_ID_NOT_EXIST_MSG  AS Error, @BOM_MASTER_ID_NOT_EXIST_CODE AS Code;
                    RETURN;
                END;


            -- Start the Transaction
            BEGIN TRANSACTION;

            -- Stop an empty @description being passed in just so that the base SP doesn't try doing a delete.
            IF (@BOMFormulationDesc = '' OR @BOMFormulationDesc = NULL)
                SET @BOMFormulationDesc = @tempDescription;

            -- Create BOM Formulation, using same existing SP as Plant Apps
            -- Run the SP, passing the NULL @tempBomFormulationId in, so that "spEM_BOMSaveFormulation" doesn't try to do an update.
            EXECUTE dbo.spEM_BOMSaveFormulation @BOM     = @BOMId,                       -- BOM Master
                                                @efdate  = @EffectiveDate,               -- Effective Date
                                                @exdate  = @ExpirationDate,              -- Expiration Date
                                                @qty     = @Quantity,                    -- Quantity
                                                @qtyprec = @Precision,                   -- Quantity Precision
                                                @eu      = @UnitId,                      -- Engineering Unit Id
                                                @Comment = @tempComment,                 -- Comment
                                                @Master  = @tempMasterTemplate,          -- Master BOM formulation Id - Not the same as BOM Master - used as a template
                                                @User    = @UserId,                      -- User for Comment
                                                @Desc    = @BOMFormulationDesc,          -- BOM Formulation Desc
                                                @Id      = @tempBomFormulationId OUTPUT; -- BOM Formulation Id

            -- If the BOM Formulation created successfully, then add the BOM Formulation Revision record
            IF (@tempBomFormulationId IS NOT NULL)
            BEGIN
                -- Create Bom Formulation Revision record
                INSERT
                  INTO dbo.Bill_Of_Material_Formulation_Revision
                       (BOM_Formulation_Id,
                        Revision,
                        BOM_Formulation_Desc,
                        Status,
                        Created_By,
                        Created_On,
                        Last_Modified_By,
                        Last_Modified_On)
                VALUES (@tempBomFormulationId,
                        @Revision,
                        @BOMFormulationDesc,
                        @Status,
                        @Created_by,
                        dbo.fnServer_CmnGetDate(GETUTCDATE()),
                        @Modified_by,
                        dbo.fnServer_CmnGetDate(GETUTCDATE()));
            END;

            -- Pass the new BOM Formulation Id back out of the SP
            SET @BOM_Formulation_Id = @tempBomFormulationId;


            -- Commit and Return the BOM Formulation Id back out
            COMMIT TRANSACTION;
            RETURN @BOM_Formulation_Id;

        END TRY
        BEGIN CATCH
            -- Simple Rollback
            IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

            -- Push the caught error up out of the SP
            THROW;

            RETURN;
        END CATCH;




    /* UPDATE an existing BOM Formulation Item */
    ELSE IF (@ParamType = @PARAMUPDATE)
        BEGIN TRY

            -- VALIDATION - pre update
            -- make sure that the incoming BOM formulation Id exists
            IF NOT EXISTS (SELECT 1 FROM dbo.Bill_Of_Material_Formulation bomf WHERE bomf.BOM_Formulation_Id = @BOM_Formulation_Id)
                BEGIN
                    SELECT @FORMULATION_ID_NOT_EXIST_MSG  AS Error, @FORMULATION_ID_NOT_EXIST_CODE AS Code;
                    RETURN;
                END;
            -- make sure that the incoming BOM Master Id (BOMId) exists
            IF NOT EXISTS (SELECT 1 FROM dbo.Bill_Of_Material bommas WHERE bommas.BOM_Id = @BOMId)
                BEGIN
                    SELECT @BOM_MASTER_ID_NOT_EXIST_MSG  AS Error, @BOM_MASTER_ID_NOT_EXIST_CODE AS Code;
                    RETURN;
                END;
            -- make sure that the incoming Eng Unit Id exists
            IF NOT EXISTS (SELECT 1 FROM dbo.Engineering_Unit engunit WHERE engunit.Eng_Unit_Id = @UnitId)
                BEGIN
                    SELECT @ENG_UNIT_ID_NOT_EXIST_MSG  AS Error, @ENG_UNIT_ID_NOT_EXIST_CODE AS Code;
                    RETURN;
                END;


            -- Start the Transaction
            BEGIN TRANSACTION;

            -- Declarations specific to UPDATE
            DECLARE @tempBOMId              INT,
                    @tempBOMFormulationDesc NVARCHAR(50),
                    @tempEffectiveDate      DATETIME, 
                    @tempExpirationDate     DATETIME,
                    @tempUnitId             INT,
                    @tempPrecision          INT,
                    @tempQuantity           FLOAT,
                    @tempStatus             NVARCHAR(25),
                    @tempModified_by        NVARCHAR(50);


            -- Get the BOM Formulation Id ready for an update
            SET @tempBomFormulationId = @BOM_Formulation_Id;

            -- Gather the BOM formulation details for the update. If the passed in value is NULL, then we reuse the existing value in the table.
            -- This will protect against loss of values
            -- BOM Formulation
            SELECT @tempBOMId              = ISNULL(@BOMId,              BOM_Id),
                   @tempBOMFormulationDesc = ISNULL(@BOMFormulationDesc, BOM_Formulation_Desc),
                   @tempEffectiveDate      = ISNULL(@EffectiveDate,      Effective_Date),
                   @tempExpirationDate     = @ExpirationDate,
                   @tempUnitId             = ISNULL(@UnitId,             Eng_Unit_Id),
                   @tempPrecision          = ISNULL(@Precision,          Quantity_Precision),
                   @tempQuantity           = ISNULL(@Quantity,           Standard_Quantity),
                   @tempMasterTemplate     = Master_BOM_Formulation_Id
              FROM dbo.Bill_Of_Material_Formulation bomfor
             WHERE bomfor.BOM_Formulation_Id = @BOM_Formulation_Id;

            -- Stop an empty @description being passed in just so that the base SP doesn't try doing a delete.
            IF (@tempBOMFormulationDesc = '' OR @tempBOMFormulationDesc = NULL)
                SET @tempBOMFormulationDesc = @tempDescription;

            -- UPDATE BOM Formulation, using same existing SP as Plant Apps
            -- Run the SP, passing the valid @tempBomFormulationId in, so that "spEM_BOMSaveFormulation" will try to do an update.
            EXECUTE dbo.spEM_BOMSaveFormulation @BOM     = @tempBOMId,                   -- BOM Master
                                                @efdate  = @tempEffectiveDate,           -- Effective Date
                                                @exdate  = @tempExpirationDate,          -- Expiration Date
                                                @qty     = @tempQuantity,                -- Quantity
                                                @qtyprec = @tempPrecision,               -- Quantity Precision
                                                @eu      = @tempUnitId,                  -- Engineering Unit Id
                                                @Comment = @tempComment,                 -- Comment
                                                @Master  = @tempMasterTemplate,          -- Master BOM formulation Id - Not the same as BOM Master - used as a template
                                                @User    = @UserId,                      -- User for Comment
                                                @Desc    = @tempBOMFormulationDesc,      -- BOM Formulation Desc
                                                @Id      = @tempBomFormulationId OUTPUT; -- BOM Formulation Id

            -- If the BOM Formulation updated successfully, then create/update the BOM Formulation Revision record
            IF (@tempBomFormulationId IS NOT NULL)
            BEGIN
                IF EXISTS (SELECT 1 FROM dbo.Bill_Of_Material_Formulation_Revision bomr WHERE bomr.BOM_Formulation_Id = @tempBomFormulationId)
                    BEGIN
                        --UPDATE Existing record
                        -- Get existing BOM "Revision" details if incoming parameters are NULL
                        SELECT @tempStatus      = ISNULL(@Status,      Status),
                               @tempModified_by = ISNULL(@Modified_by, Last_Modified_By)
                          FROM dbo.Bill_Of_Material_Formulation_Revision bomrev
                         WHERE bomrev.BOM_Formulation_Id = @tempBomFormulationId;

                       -- Update Bom Formulation Revision record
                        UPDATE dbo.Bill_Of_Material_Formulation_Revision
                           SET BOM_Formulation_Desc = @tempBOMFormulationDesc,
                               Status               = @tempStatus,
                               Last_Modified_By     = @tempModified_by,
                               Last_Modified_On     = dbo.fnServer_CmnGetDate(GETUTCDATE())
                         WHERE BOM_Formulation_Id = @tempBomFormulationId;
                    END;
                ELSE
                    BEGIN
                        -- CREATE NEW record, as the incoming BOM Formulation will have been created in the PlantApps Thick Client

                        -- Create Bom Formulation Revision record, with no created details
                        INSERT
                          INTO dbo.Bill_Of_Material_Formulation_Revision
                               (BOM_Formulation_Id,
                                Revision,
                                BOM_Formulation_Desc,
                                Status,
                                Created_By,
                                Created_On,
                                Last_Modified_By,
                                Last_Modified_On)
                        VALUES (@tempBomFormulationId,
                                @Revision,
                                @tempBOMFormulationDesc,
                                @Status,
                                NULL, -- Created_By
                                NULL, -- Created_On
                                @Modified_by,
                                dbo.fnServer_CmnGetDate(GETUTCDATE()));
                    END;
            END;


            -- Cleanup incase used later
            SET @tempMasterTemplate = NULL;

            -- Commit and Return the BOM Formulation Id back out
            COMMIT TRANSACTION;
            RETURN @BOM_Formulation_Id;

        END TRY
        BEGIN CATCH
            -- Simple Rollback
            IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

            -- Push the caught error up out of the SP
            THROW;

            RETURN;
        END CATCH;




    /* DELETE an existing BOM Formulation */
    ELSE IF (@ParamType = @PARAMDELETE)
        BEGIN TRY

            -- VALIDATION - pre delete
            -- make sure that the incoming BOM formulation Id exists
            IF NOT EXISTS (SELECT 1 FROM dbo.Bill_Of_Material_Formulation bomf WHERE bomf.BOM_Formulation_Id = @BOM_Formulation_Id)
                BEGIN
                    SELECT @FORMULATION_ID_NOT_EXIST_MSG  AS Error, @FORMULATION_ID_NOT_EXIST_CODE AS Code;
                    RETURN;
                END;

            -- Start the Transaction
            BEGIN TRANSACTION;

            -- Declarations specific to DELETE
            DECLARE @tempDeleteDescription NVARCHAR(50) = '';

            -- Get the BOM Formulation Id ready for delete
            SET @tempBomFormulationId = @BOM_Formulation_Id;

            -- Delete Revision
            IF (@tempBomFormulationId IS NOT NULL)
            BEGIN
                DELETE
                  FROM dbo.Bill_Of_Material_Formulation_Revision
                 WHERE BOM_Formulation_Id = @BOM_Formulation_Id;
            END;

            -- Run the SP. For a delete, the base SP only requires a BOM Formulation ID, and an empty string for the Description
            EXECUTE dbo.spEM_BOMSaveFormulation @BOM     = NULL,
                                                @efdate  = NULL,
                                                @exdate  = NULL,
                                                @qty     = NULL,
                                                @qtyprec = NULL,
                                                @eu      = NULL,
                                                @Comment = NULL,
                                                @Master  = NULL,
                                                @User    = NULL,
                                                @Desc    = @tempDeleteDescription,       -- BOM Formulation Desc
                                                @Id      = @tempBomFormulationId OUTPUT; -- BOM Formulation Id

            -- Commit and Return the BOM Formulation Id back out
            COMMIT TRANSACTION;
            RETURN @BOM_Formulation_Id;

        END TRY
        BEGIN CATCH
            -- Simple Rollback
            IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

            -- Push the caught error up out of the SP
            THROW;

            RETURN;
        END CATCH;




    /* We didn't get a valid partamType, so DO NOTHING */
    ELSE
        BEGIN
            -- exit back out to the caller.
            RETURN;
        END;

END;


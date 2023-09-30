﻿CREATE TABLE [dbo].[Local_MPWS_IMPORT_PM_SECTION_LG] (
    [ORDER_ID]            NVARCHAR (255) NULL,
    [BATCH_ID]            NVARCHAR (255) NULL,
    [STAGE_ID]            NVARCHAR (255) NULL,
    [SECTION_ID]          NVARCHAR (255) NULL,
    [ENTRY_TIMESTAMP]     DATETIME       NULL,
    [SECT_PROD_ID]        NVARCHAR (255) NULL,
    [SECT_PROD_DESC]      NVARCHAR (255) NULL,
    [SECT_PROD_QTY]       FLOAT (53)     NULL,
    [SECT_PROD_UOM]       NVARCHAR (255) NULL,
    [UNIT_ID]             NVARCHAR (255) NULL,
    [SCALE_FACTOR]        FLOAT (53)     NULL,
    [SCHED_BEGIN_TIME]    DATETIME       NULL,
    [SCHED_END_TIME]      NVARCHAR (255) NULL,
    [ACTUAL_BEGIN_TIME]   NVARCHAR (255) NULL,
    [ACTUAL_END_TIME]     NVARCHAR (255) NULL,
    [SECTION_STATUS]      NVARCHAR (255) NULL,
    [OSV_PROC_NO]         NVARCHAR (255) NULL,
    [USER_NAME]           NVARCHAR (255) NULL,
    [VERIFIER_NAME]       NVARCHAR (255) NULL,
    [STEP_NAME]           NVARCHAR (255) NULL,
    [STEP_INSTANCE]       FLOAT (53)     NULL,
    [SIGNATURE]           NVARCHAR (255) NULL,
    [DISPENSE_STATUS]     NVARCHAR (255) NULL,
    [MATERIAL_STATUS]     NVARCHAR (255) NULL,
    [DISPENSE_KIT_STATUS] NVARCHAR (255) NULL,
    [MATL_STAGING_STATUS] NVARCHAR (255) NULL
);

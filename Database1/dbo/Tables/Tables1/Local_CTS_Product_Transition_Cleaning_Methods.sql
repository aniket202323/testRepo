CREATE TABLE [dbo].[Local_CTS_Product_Transition_Cleaning_Methods] (
    [CPTCM_id]        INT      IDENTITY (1, 1) NOT NULL,
    [From_Product_id] INT      NOT NULL,
    [To_Product_id]   INT      NOT NULL,
    [Location_id]     INT      NULL,
    [CCM_id]          INT      NOT NULL,
    [Start_Time]      DATETIME NOT NULL,
    [End_Time]        DATETIME NULL,
    [Parent_CPTCM_id] INT      NULL,
    CONSTRAINT [Local_CTS_Product_Transition_Cleaning_Methods_PK_CPTCM_id] PRIMARY KEY CLUSTERED ([CPTCM_id] ASC),
    CONSTRAINT [Local_CTS_Product_transition_Cleaning_Methods_FK_CCMid] FOREIGN KEY ([CCM_id]) REFERENCES [dbo].[Local_CTS_Cleaning_Methods] ([CCM_id]),
    CONSTRAINT [Local_CTS_Product_transition_Cleaning_Methods_FK_CPTCMid] FOREIGN KEY ([Parent_CPTCM_id]) REFERENCES [dbo].[Local_CTS_Product_Transition_Cleaning_Methods] ([CPTCM_id])
);


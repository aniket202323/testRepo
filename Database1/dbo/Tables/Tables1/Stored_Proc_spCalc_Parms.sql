CREATE TABLE [dbo].[Stored_Proc_spCalc_Parms] (
    [SP_Parm_Id] INT                   NOT NULL,
    [spCalc_Id]  INT                   NOT NULL,
    [Value]      [dbo].[Varchar_Value] NOT NULL,
    CONSTRAINT [SPCParams_PK_spCalcIdSPParmId] PRIMARY KEY NONCLUSTERED ([spCalc_Id] ASC, [SP_Parm_Id] ASC)
);


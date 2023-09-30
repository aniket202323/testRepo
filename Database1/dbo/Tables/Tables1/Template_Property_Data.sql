CREATE TABLE [dbo].[Template_Property_Data] (
    [Data_Type_Id] INT                       NOT NULL,
    [Eng_Units]    [dbo].[Varchar_Eng_Units] NULL,
    [PU_Id]        INT                       NOT NULL,
    [ST_Id]        INT                       NOT NULL,
    [Template_Id]  INT                       NOT NULL,
    [TP_Id]        INT                       NOT NULL,
    [Value]        [dbo].[Varchar_Value]     NULL,
    [Var_Id]       INT                       NULL,
    CONSTRAINT [TmpPropData_PK_PUIdTmpIdTPId] PRIMARY KEY NONCLUSTERED ([PU_Id] ASC, [Template_Id] ASC, [TP_Id] ASC)
);


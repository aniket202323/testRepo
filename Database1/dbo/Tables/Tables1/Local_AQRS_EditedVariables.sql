CREATE TABLE [dbo].[Local_AQRS_EditedVariables] (
    [EditVarId]      INT            IDENTITY (1, 1) NOT NULL,
    [VarId]          INT            NULL,
    [VarDesc]        VARCHAR (50)   NULL,
    [VarAttr]        VARCHAR (25)   NULL,
    [Impact]         VARCHAR (25)   NULL,
    [ProdId]         INT            NOT NULL,
    [LineId]         INT            NOT NULL,
    [Result]         VARCHAR (25)   NULL,
    [L_Reject]       VARCHAR (25)   NULL,
    [L_User]         VARCHAR (25)   NULL,
    [Target]         VARCHAR (25)   NULL,
    [U_User]         VARCHAR (25)   NULL,
    [U_Reject]       VARCHAR (25)   NULL,
    [AddedValues]    VARCHAR (4000) NULL,
    [AddedLimits]    VARCHAR (4000) NULL,
    [TimestampTest]  DATETIME       NOT NULL,
    [TimestampAdded] DATETIME       NOT NULL,
    [IsVarNumeric]   INT            NULL,
    [IsEdit]         BIT            NULL,
    [IsAdd]          BIT            NULL,
    CONSTRAINT [LocalAQRSEditedVariables_PK_EditVarId] PRIMARY KEY CLUSTERED ([EditVarId] ASC)
);


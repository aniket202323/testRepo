CREATE TABLE [dbo].[FIXALARMS] (
    [ALM_NATIVETIMEIN]   DATETIME         NULL,
    [ALM_NATIVETIMELAST] DATETIME         NULL,
    [ALM_LOGNODENAME]    CHAR (10)        NULL,
    [ALM_PHYSLNODE]      CHAR (10)        NULL,
    [ALM_TAGNAME]        CHAR (256)       NULL,
    [ALM_TAGDESC]        CHAR (256)       NULL,
    [ALM_VALUE]          CHAR (40)        NULL,
    [ALM_MSGTYPE]        CHAR (11)        NULL,
    [ALM_DESCR]          CHAR (480)       NULL,
    [ALM_ALMEXTFLD1]     CHAR (80)        NULL,
    [ALM_PERFFULLNAME]   CHAR (80)        NULL,
    [ALM_PERFBYCOMMENT]  CHAR (170)       NULL,
    [ALM_VERNAME]        CHAR (32)        NULL,
    [ALM_VERFULLNAME]    CHAR (80)        NULL,
    [ALM_VERBYCOMMENT]   CHAR (170)       NULL,
    [ALM_MSGID]          UNIQUEIDENTIFIER NULL,
    [ALM_DATEIN]         CHAR (12)        NULL,
    [ALM_TIMEIN]         CHAR (15)        NULL,
    [ALM_DATELAST]       CHAR (12)        NULL,
    [ALM_TIMELAST]       CHAR (15)        NULL
);


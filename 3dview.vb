Imports System.Web.Script.Serialization

Partial Class three3dview
    Inherits System.Web.UI.Page

    Public ArrowJson As String
    Public GlowBallJson As String

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        ' 模擬從資料庫或邏輯取得資料
        Dim arrows = New List(Of Object) From {
            New With {.pos = New With {.x = 0, .y = 0.5, .z = 0},
                      .dir = New With {.x = 0, .y = 1, .z = 0},
                      .len = 2,
                      .color = &HFF3333,
                      .url = "https://example.com/a"},
            New With {.pos = New With {.x = 3, .y = 0.5, .z = 1},
                      .dir = New With {.x = 1, .y = 0, .z = 0},
                      .len = 2.5,
                      .color = &H33FF33,
                      .url = "https://example.com/b"},
            New With {.pos = New With {.x = -2, .y = 0.5, .z = -3},
                      .dir = New With {.x = 0, .y = 0, .z = -1},
                      .len = 1.5,
                      .color = &H3333FF,
                      .url = "https://example.com/c"}
        }

        Dim glowBalls = New List(Of Object) From {
            New With {.pos = New With {.x = 2, .y = 1, .z = -1},
                      .color = &H00FF88,
                      .url = "https://example.com/light1"}
        }

        Dim js As New JavaScriptSerializer()
        ArrowJson = js.Serialize(arrows)
        GlowBallJson = js.Serialize(glowBalls)
    End Sub
End Class

Imports System.Web.Script.Serialization

Partial Class three3dview
    Inherits System.Web.UI.Page

    Public ObjectJson As String

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        Dim objs As New List(Of Object)

        ' === 三個箭頭 + 三個光球示例 ===
        Dim dirs() As (Double, Double, Double) = { (0, 0, 1), (1, 0, 0), (-1, 0, 1) }
        For i As Integer = 0 To 2
            ' 箭頭
            objs.Add(New With {
                .type = "arrow",
                .tooltip = $"這是第 {i + 1} 個箭頭",
                .pos = New With {.x = i * 2 - 2, .y = 1.5, .z = 0},
                .dir = New With {.x = dirs(i).Item1, .y = dirs(i).Item2, .z = dirs(i).Item3}
            })

            ' 光球
            objs.Add(New With {
                .type = "light",
                .tooltip = $"這是第 {i + 1} 顆光球",
                .pos = New With {.x = i * 2 - 2, .y = 2, .z = -2}
            })
        Next

        Dim js As New JavaScriptSerializer()
        ObjectJson = js.Serialize(objs)
    End Sub
End Class


******************************
**SETTING UP HYPERLING CODE IN EXCEL**
******************************

mata: 
mata clear
void basic_formatting(string scalar filename, string scalar sheet, string matrix vars, string matrix colors, real scalar nrow) 
{

class xl scalar b
real scalar i, ncol
real vector column_widths, varname_widths, bottomrows
real matrix bottom

b = xl()
ncol = length(vars)

b.load_book(filename)
b.set_sheet(sheet)
b.set_mode("open")

b.set_bottom_border(1, (1, ncol), "thin")
b.set_font_bold(1, (1, ncol), "on")
b.set_horizontal_align(1, (1, ncol), "center")

if (length(colors) > 1 & nrow > 2) {	
for (j=1; j<=length(colors); j++) {
	b.set_font((3, nrow+1), strtoreal(colors[j]), "Calibri", 11, "lightgray")
	}
}


// Add separating bottom lines : figure out which columns to gray out	
bottom = st_data(., st_local("bottom"))
bottomrows = selectindex(bottom :== 1)
column_widths = colmax(strlen(st_sdata(., vars)))	
varname_widths = strlen(vars)

for (i=1; i<=cols(column_widths); i++) {
	if	(column_widths[i] < varname_widths[i]) {
		column_widths[i] = varname_widths[i]
	}

	b.set_column_width(i, i, column_widths[i] + 2)
}

if (rows(bottomrows) > 1) {
for (i=1; i<=rows(bottomrows); i++) {
	b.set_bottom_border(bottomrows[i]+1, (1, ncol), "thin")
	if (length(colors) > 1) {
		for (k=1; k<=length(colors); k++) {
			b.set_font(bottomrows[i]+2, strtoreal(colors[k]), "Calibri", 11, "black")
		}
	}
}
}
else b.set_bottom_border(2, (1, ncol), "thin")

b.close_book()

}

void add_scto_link(string scalar filename, string scalar sheetname, string scalar variable, real scalar col, real scalar rowbeg, real scalar rowend)
{
	class xl scalar b
	string matrix links
	real scalar N

	b = xl()
	links = st_sdata(., variable)
	N = length(links) + 2

	b.load_book(filename)
	b.set_sheet(sheetname)
	b.set_mode("open")
	b.put_formula(rowbeg, col, links)
	b.set_font((rowbeg, rowend), col, "Calibri", 11, "5 99 193")
	b.set_font_underline((rowbeg, rowend), col, "on")
	b.set_column_width(col, col, 17)
	b.close_book()
	}
	
void check_list_format(string scalar filename, string scalar sheetname, string scalar variable, real scalar col, real scalar rowbeg, real scalar rowend, real scalar nvar)
{
	class xl scalar b
	string matrix links
	real scalar Nrow

	b = xl()
	links = st_sdata(., variable)
	Nrow = length(links) + 2
	
	
	b.load_book(filename)
	b.set_sheet(sheetname)
	b.set_mode("open")
	b.set_border((rowbeg,rowend), (col,nvar), "thin")
	b.close_book()
	}

end



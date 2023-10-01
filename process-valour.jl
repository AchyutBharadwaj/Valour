using Dates
using DataFrames
using CSV

const sci = "(?i)"
const snx = "([^0-9]+)"

const s12d = "(0?[1-9]|([1-2][0-9])|3[0-1])"
const s12m = "(0?[0-9]|1[0-2])"
const smon = "(Jan(uary)?|Feb(ruary)?|Mar(ch)?|Apr(il)?|May|Jun(e)?|Jul(y)?|Aug(ust)?|Sep(t|tember)?|Oct(ober)?|Nov(ember)?|Dec(ember)?)"
const s24y = "((\\d\\d)?\\d\\d)"
const sep = "[\\.\\-\\/\\\\]"
const sdx = "(($s12d$sep($s12m|$smon)$sep$s24y)|($s24y$sep($s12m|$smon)$sep$s12d))"

const rnxrdx = Regex("$sci$snx$sdx")
const rdx = Regex("$sci$sdx")
const rnx = Regex("$snx")

function getCol(header::Vector{String}, cat::AbstractString)
  category = cat=="BU12" ? "U-12 Category"   :
             cat=="BU14" ? "U-14 Category "  :
             cat=="BU16" ? "U-16 Category "  :
             cat=="BU18" ? "U-18 Category"   :
             cat=="GU12" ? "U-12 Category_1" :
             cat=="GU14" ? "U-14 Category"   :
             cat=="GU16" ? "U-16 Category"   :
             cat=="GU18" ? "U-18 Category_1" : nothing
  findall(x->x==category,header)[1]+1
end

getDOBs(instr::Missing) = Vector{String}(), Vector{Date}()

function getDOBs(instr::AbstractString)
  DOBs = Vector{Date}()
  Names = Vector{String}()
  inlist = split(replace(instr,rnxrdx=>s"\1\2:"),":")
  for x in inlist
    mDOBs = match(rdx,x)
    if (mDOBs != nothing)
      y = replace(strip(mDOBs.match),Regex(sep)=>"-")
      z = occursin(r"(?i)(January|February|March|April|June|July|August|September|October|November|December)", y) ? Date(y,Dates.dateformat"d-U-y") :
          occursin(r"(?i)(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)", y) ? Date(y,Dates.dateformat"d-u-y") : Date(y,Dates.dateformat"d-m-y")
      z = year(z)<2000 ? z+Year(2000) : z
      push!(DOBs,Date(z))
    end
    mNames = match(rnx,replace(replace(replace(x,rdx=>""),r"[^A-Za-z ]"=>""),r"\s\s+"=>" "))
    if (mNames != nothing)
      push!(Names,strip(mNames.match))
    end
  end
  return Names, DOBs
end

data=CSV.read("valournew.csv", DataFrame)
h=names(data)

for i in 1:size(data)[1]
  for c in ["BU12","BU14","BU16","BU18","GU12","GU14","GU16","GU18"]
    println("School: $(strip(data[i,"Name of School"])), Category: $c")
    Names, DOBs = getDOBs(data[i,getCol(h, c)])
    for j = 1 : min(length(Names),length(DOBs))
        println("Name: $(Names[j]), DOB: $(DOBs[j]), Age: $(Int(ceil((Date("2023-01-01")-DOBs[j]).value/365)))")
    end
    print("\n")
  end
end

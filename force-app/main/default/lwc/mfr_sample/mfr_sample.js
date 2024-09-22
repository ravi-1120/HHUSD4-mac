import { LightningElement, api,track  } from 'lwc';
export default class Mfr_sample extends LightningElement {
    @api recordId;
    @track indication = "<p><b style=\"font-size: 24px; color: rgb(0, 0, 0);\">Indication</b></p><p><br></p><p><span style=\"font-size: 16px;\">BRIDION® (sugammadex) is indicated for the reversal of neuromuscular blockade induced by rocuronium bromide and vecuronium bromide in adults undergoing surgery.</span></p><p><br></p><p><b style=\"font-size: 24px;\">Selected Safety Information</b></p><p><br></p><p><span style=\"font-size: 16px;\">BRIDION is contraindicated in patients with known hypersensitivity to sugammadex or any of its components. Hypersensitivity reactions that occurred varied from isolated skin reactions to serious systemic reactions (i.e., anaphylaxis, anaphylactic shock) and have occurred in patients with no prior exposure to sugammadex.</span></p><p><br></p><p><span style=\"font-size: 16px;\">Potentially serious hypersensitivity reactions, including anaphylaxis, have occurred in patients treated with BRIDION. In a clinical study, anaphylaxis occurred in 0.3% (n=1/299) of healthy volunteers treated with BRIDION. The most common hypersensitivity adverse reactions reported were nausea, pruritus and urticaria and showed a dose response relationship, occurring more frequently in the 16 mg/kg group compared to the 4 mg/kg and placebo groups. Observe patients for an appropriate period of time after administration and take the necessary precautions. Anaphylaxis has also been reported in the post-marketing setting. Clinical features in anaphylaxis reports have included dermatologic symptoms; hypotension often requiring the use of vasopressors; and prolonged hospitalization and/or the use of additional respiratory support until full recovery.</span></p><p><br></p><p><span style=\"font-size: 16px;\">Cases of marked bradycardia, some of which have resulted in cardiac arrest, have been observed within minutes after the administration of BRIDION. Monitor for hemodynamic changes and treat with anticholinergic agents, such as atropine, if clinically significant bradycardia is observed.</span></p><p><br></p><p><span style=\"font-size: 16px;\">Ventilatory support is mandatory for patients until adequate spontaneous respiration is restored and the ability to maintain a patent airway is assured. Should neuromuscular blockade persist after BRIDION or recur following extubation, take appropriate steps to provide adequate ventilation.</span></p><p><br></p><p><span style=\"font-size: 16px;\">In clinical trials, a small number of patients experienced a delayed or minimal response to BRIDION. Monitor ventilation until recovery occurs.</span></p><p><br></p><p><span style=\"font-size: 16px;\">A minimum waiting time is necessary before re-administration of a steroidal neuromuscular blocking agent after administration of BRIDION.</span></p><p><br></p><p><b style=\"font-size: 18px;\">Re-administration of Rocuronium or Vecuronium after Reversal (up to 4 mg/kg BRIDION)</b></p><p><br></p><p><b style=\"font-size: 18px;\">﻿</b><img src=\"https://focal4-dev-ed--c.documentforce.com/servlet/rtaImage?eid=a015i00000BfS6I&amp;feoid=00N5i000003buq1&amp;refid=0EM5i000001DJ0H\" alt=\"Bridion table.png\"></img></p><p><span style=\"font-size: 16px;\">If neuromuscular blockade is required before the recommended waiting time has elapsed, use a nonsteroidal neuromuscular blocking agent.</span></p><p><br></p><ul><li><span style=\"font-size: 16px;\">Due to the administration of BRIDION, certain drugs, including hormonal contraceptives, could become less effective due to a lowering of the (free) plasma concentrations. Consider re-administration of the other drug, administration of a therapeutic equivalent drug, and/or non-pharmacological interventions as appropriate. If an oral contraceptive is taken on the same day that BRIDION is administered, the patient must use an additional, non-hormonal contraceptive method or back-up method of contraception (such as condoms and spermicides) for the next 7 days. In the case of non-oral hormonal contraceptives, the patient must use an additional, non-hormonal contraceptive method or back-up method of contraception (such as condoms and spermicides) for the next 7 days.</span></li><li><span style=\"font-size: 16px;\">Recurrence of neuromuscular blockade may occur due to displacement of rocuronium or vecuronium from BRIDION by other drugs. Mechanical ventilation may be required. Stop the administration of the drug which caused displacement, if being administered by infusion.</span></li><li><span style=\"font-size: 16px;\">The use of lower than recommended doses of BRIDION may lead to an increased risk of recurrence of neuromuscular blockade and is not recommended. Also, when drugs which potentiate neuromuscular blockade are used in the post-operative phase, recurrence of neuromuscular blockade is possible.</span></li><li><span style=\"font-size: 16px;\">BRIDION doses of up to 16 mg/kg were associated with increases in activated partial thromboplastin time and prothrombin time/international normalized ratio. Carefully monitor coagulation parameters in patients with known coagulopathies; being treated with therapeutic anticoagulation; receiving thromboprophylaxis drugs other than heparin and low molecular weight heparin; or receiving thromboprophylaxis drugs and who then receive a dose of 16 mg/kg sugammadex.</span></li><li><span style=\"font-size: 16px;\">BRIDION is not recommended for use in patients with severe renal impairment, including those requiring dialysis.</span></li><li><span style=\"font-size: 16px;\">BRIDION has not been studied for reversal following rocuronium or vecuronium administration in the ICU.</span></li><li><span style=\"font-size: 16px;\">Do not use BRIDION to reverse nonsteroidal neuromuscular blocking agents or steroidal neuromuscular blocking agents other than rocuronium or vecuronium.</span></li><li><span style=\"font-size: 16px;\">The most common adverse reactions (reported in ≥ 10% of patients at a 2, 4, or 16 mg/kg BRIDION dose and higher than placebo rate) were vomiting (11%, 12%, or 15% versus placebo at 10%), pain (48%, 52%, or 36% versus placebo at 38%), nausea (23%, 26%, or 23% versus placebo at 23%), hypotension (4%, 5%, or 13% versus placebo at 4%), and headache (7%, 5%, or 10% versus placebo at 8%).</span></li></ul><p><b style=\"font-size: 24px;\">Before prescribing BRIDION, please read the accompanying </b><a href=\"https://focal4-dev-ed.my.salesforce.com/sfc/p/5i00000137Fe/a/5i000000br73/L2Q_Wgt1EseZoEPXTIuquvkn3S5Vdmd00arNPpywQ5M\" target=\"_blank\" style=\"font-size: 24px; color: rgb(0, 135, 124);\"><b><u>Prescribing Information</u></b></a><b style=\"font-size: 24px; color: rgb(0, 135, 124);\"><u>.</u></b><b style=\"font-size: 24px;\"> The </b><a href=\"https://www.merck.com/product/usa/pi_circulars/v/verquvo/verquvo_mg.pdf\" target=\"_blank\" style=\"font-size: 24px; color: rgb(0, 135, 124);\"><b><u>Medication Guide</u></b></a><b style=\"font-size: 24px;\"> also is available.</b></p>";
    handleSectionToggle(event) {
        const openSections = event.detail.openSections;
        if (openSections.length === 0) {
            this.activeSectionsMessage = 'All sections are closed';
        } else {
            this.activeSectionsMessage =
                'Open sections: ' + openSections.join(', ');
        }
       
    }

    onsectiontoggle(event) {
    let openSections = event.detail.openSections;
    let sections = this.template.querySelectorAll(
      "lightning-accordion-section"
    );
    sections.forEach((section) => {
      section.dataset.open = !!(openSections.indexOf(section.name) > -1);
    });
  }

  accordclick() {
    var acc = document.getElementsByClassName("accordion");
    var i;

    for (i = 0; i < acc.length; i++) {
      acc[i].addEventListener("click", function() {
        this.classList.toggle("active");
        var panel = this.nextElementSibling;
        if (panel.style.display === "block") {
          panel.style.display = "none";
        } else {
          panel.style.display = "block";
        }
      });
    }
  }
}